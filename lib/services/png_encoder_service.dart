import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Encodeur PNG binaire pur respectant au bit près la signature WebKit/Capacitor iOS :
/// - Résolution 640x480 px
/// - Palette indexée 1-bit (Color type 3, Bit depth 1)
/// - Palette PLTE : #000000 / #040204
/// - Chunk tRNS (index 0 transparent)
/// - Chunk pHYs (3780 ppm = 96.012 DPI)
class PngEncoderService {
  static const int width = 640;
  static const int height = 480;
  static const int rowBytes = 80; // 640 pixels / 8 bits

  /// Table CRC32 précalculée
  static final List<int> _crcTable = _initCrcTable();

  static List<int> _initCrcTable() {
    final table = List<int>.filled(256, 0);
    for (int n = 0; n < 256; n++) {
      int c = n;
      for (int k = 0; k < 8; k++) {
        if ((c & 1) != 0) {
          c = 0xEDB88320 ^ (c >>> 1);
        } else {
          c = c >>> 1;
        }
      }
      table[n] = c;
    }
    return table;
  }

  static int _calculateCrc(List<int> typeAndData) {
    int crc = 0xFFFFFFFF;
    for (final b in typeAndData) {
      crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >>> 8);
    }
    return crc ^ 0xFFFFFFFF;
  }

  static Uint8List _buildChunk(String type, List<int> data) {
    final typeBytes = type.codeUnits;
    final payload = [...typeBytes, ...data];
    final crc = _calculateCrc(payload);

    final result = BytesBuilder();
    // Length (4 bytes big-endian)
    result.add([
      (data.length >>> 24) & 0xFF,
      (data.length >>> 16) & 0xFF,
      (data.length >>> 8) & 0xFF,
      data.length & 0xFF,
    ]);
    // Type + Data
    result.add(payload);
    // CRC (4 bytes big-endian)
    result.add([
      (crc >>> 24) & 0xFF,
      (crc >>> 16) & 0xFF,
      (crc >>> 8) & 0xFF,
      crc & 0xFF,
    ]);
    return result.toBytes();
  }

  /// Encode un bitmap 640x480 (tableau de 480 lignes x 80 octets) en PNG 1-bit conforme
  static Uint8List encode1BitPng(List<Uint8List> rows) {
    assert(rows.length == height);
    final builder = BytesBuilder();

    // 1. Signature PNG
    builder.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

    // 2. Chunk IHDR (640x480, 1-bit, palette color_type 3)
    final ihdrData = [
      0x00, 0x00, 0x02, 0x80, // width: 640
      0x00, 0x00, 0x01, 0xE0, // height: 480
      0x01, // bit depth: 1
      0x03, // color type: 3 (palette)
      0x00, // compression: 0
      0x00, // filter: 0
      0x00, // interlace: 0
    ];
    builder.add(_buildChunk('IHDR', ihdrData));

    // 3. Chunk PLTE (Noir et Encre #040204)
    final plteData = [
      0x00, 0x00, 0x00, // Index 0: Fond
      0x04, 0x02, 0x04, // Index 1: Encre WebKit
    ];
    builder.add(_buildChunk('PLTE', plteData));

    // 4. Chunk tRNS (Transparence de l'index 0)
    builder.add(_buildChunk('tRNS', [0x00]));

    // 5. Chunk pHYs (3780 pixels/mètre = 96.012 DPI)
    final physData = [
      0x00, 0x00, 0x0E, 0xC4, // X axis: 3780
      0x00, 0x00, 0x0E, 0xC4, // Y axis: 3780
      0x01, // Meter unit
    ];
    builder.add(_buildChunk('pHYs', physData));

    // 6. Scanlines IDAT avec filtre 0 (None)
    final uncompressed = BytesBuilder();
    for (int y = 0; y < height; y++) {
      uncompressed.addByte(0); // Filter byte: None
      uncompressed.add(rows[y]);
    }
    final compressedIdat = zlib.encode(uncompressed.toBytes());
    builder.add(_buildChunk('IDAT', compressedIdat));

    // 7. Chunk IEND
    builder.add(_buildChunk('IEND', []));

    return builder.toBytes();
  }

  /// Génère procéduralement une signature réaliste unique (splines lissées)
  static Uint8List generateOrganicSignaturePng({int? seed}) {
    final rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final rows = List<Uint8List>.generate(
      height,
      (_) => Uint8List(rowBytes),
    );

    void setPixel(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final byteIndex = x ~/ 8;
      final bitIndex = 7 - (x % 8);
      rows[y][byteIndex] |= (1 << bitIndex);
    }

    void drawThickPoint(double cx, double cy, double radius) {
      final r = radius.ceil();
      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          if (dx * dx + dy * dy <= radius * radius) {
            setPixel((cx + dx).round(), (cy + dy).round());
          }
        }
      }
    }

    void drawLine(double x0, double y0, double x1, double y1, double radius) {
      final dx = x1 - x0;
      final dy = y1 - y0;
      final dist = sqrt(dx * dx + dy * dy);
      final steps = (dist * 2).ceil().clamp(1, 1000);
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        drawThickPoint(x0 + dx * t, y0 + dy * t, radius);
      }
    }

    // Points de contrôle de la signature (tracé manuscrit)
    final numPoints = 6 + rng.nextInt(4);
    final startX = 140.0 + rng.nextDouble() * 50.0;
    final startY = 220.0 + rng.nextDouble() * 40.0;

    final points = <Point<double>>[Point(startX, startY)];
    double currentX = startX;
    double currentY = startY;

    for (int i = 0; i < numPoints; i++) {
      currentX += 35.0 + rng.nextDouble() * 45.0;
      currentY += (rng.nextDouble() - 0.5) * 90.0;
      currentY = currentY.clamp(140.0, 360.0);
      points.add(Point(currentX, currentY));
    }

    // Boucle finale manuscrite
    points.add(Point(currentX - 50.0 + rng.nextDouble() * 20.0, currentY + 30.0));
    points.add(Point(currentX + 60.0 + rng.nextDouble() * 30.0, currentY - 20.0));

    // Rendu en spline interpolée
    double prevX = points[0].x;
    double prevY = points[0].y;
    final strokeRadius = 1.6 + rng.nextDouble() * 0.6;

    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      drawLine(prevX, prevY, p.x, p.y, strokeRadius);
      prevX = p.x;
      prevY = p.y;
    }

    // Trait inférieur de soulignement stylisé
    final underlineStartX = startX + 15.0;
    final underlineY = 320.0 + rng.nextDouble() * 25.0;
    final underlineEndX = currentX + 30.0;
    drawLine(underlineStartX, underlineY, underlineEndX, underlineY - 5.0, strokeRadius * 0.9);

    return encode1BitPng(rows);
  }

  /// Convertit une liste de coordonnées tactiles dessinées au doigt en PNG 1-bit
  static Uint8List renderTouchStrokesToPng(List<List<Point<double>>> strokes, double canvasWidth, double canvasHeight) {
    final rows = List<Uint8List>.generate(
      height,
      (_) => Uint8List(rowBytes),
    );

    final scaleX = width / canvasWidth;
    final scaleY = height / canvasHeight;

    void setPixel(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final byteIndex = x ~/ 8;
      final bitIndex = 7 - (x % 8);
      rows[y][byteIndex] |= (1 << bitIndex);
    }

    void drawThickPoint(double cx, double cy, double radius) {
      final r = radius.ceil();
      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          if (dx * dx + dy * dy <= radius * radius) {
            setPixel((cx + dx).round(), (cy + dy).round());
          }
        }
      }
    }

    void drawLine(double x0, double y0, double x1, double y1, double radius) {
      final dx = x1 - x0;
      final dy = y1 - y0;
      final dist = sqrt(dx * dx + dy * dy);
      final steps = (dist * 2).ceil().clamp(1, 1000);
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        drawThickPoint(x0 + dx * t, y0 + dy * t, radius);
      }
    }

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        drawThickPoint(stroke[0].x * scaleX, stroke[0].y * scaleY, 2.0);
        continue;
      }
      for (int i = 0; i < stroke.length - 1; i++) {
        final p0 = stroke[i];
        final p1 = stroke[i + 1];
        drawLine(
          p0.x * scaleX,
          p0.y * scaleY,
          p1.x * scaleX,
          p1.y * scaleY,
          2.0,
        );
      }
    }

    return encode1BitPng(rows);
  }
}
