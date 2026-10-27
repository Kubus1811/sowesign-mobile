import 'dart:math';
import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  final Function(List<List<Point<double>>> strokes, double width, double height)?
      onSignatureChanged;

  const SignaturePad({super.key, this.onSignatureChanged});

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
    _notifyParent();
  }

  bool get isEmpty => _strokes.isEmpty && (_currentStroke == null || _currentStroke!.isEmpty);

  List<List<Point<double>>> get exportStrokes {
    final result = <List<Point<double>>>[];
    for (final stroke in _strokes) {
      result.add(stroke.map((p) => Point<double>(p.dx, p.dy)).toList());
    }
    if (_currentStroke != null && _currentStroke!.isNotEmpty) {
      result.add(_currentStroke!.map((p) => Point<double>(p.dx, p.dy)).toList());
    }
    return result;
  }

  void _notifyParent() {
    if (widget.onSignatureChanged != null) {
      final size = context.size ?? const Size(320, 240);
      widget.onSignatureChanged!(exportStrokes, size.width, size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Indicateur d'arrière-plan discret "Signez ici"
            if (isEmpty)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.draw_outlined, size: 36, color: Colors.grey.shade300),
                    const SizedBox(height: 6),
                    Text(
                      'Tracez votre signature au doigt',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            // Zone tactile de dessin
            GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _currentStroke = [details.localPosition];
                  _strokes.add(_currentStroke!);
                });
                _notifyParent();
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentStroke?.add(details.localPosition);
                });
                _notifyParent();
              },
              onPanEnd: (_) {
                _notifyParent();
              },
              child: CustomPaint(
                painter: _SignaturePainter(strokes: _strokes),
                size: Size.infinite,
              ),
            ),
            // Bouton effacer
            if (!isEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: clear,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.refresh_rounded, size: 18, color: Colors.grey.shade700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF040204) // Encre foncée WebKit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 1.5, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
