import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SIRRApp());
}

const pink = Color(0xFFFF4FA3);
const purple = Color(0xFF9B5CFF);
const bg = Color(0xFF08060D);

class SIRRApp extends StatelessWidget {
  const SIRRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  final codeController = TextEditingController();
  late final AnimationController animation;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    animation.dispose();
    codeController.dispose();
    super.dispose();
  }


  Future<void> openMessage() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب الرمز أولاً')),
      );
      return;
    }

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-east1',
      ).httpsCallable('readSecret');

      final result = await callable.call({'code': code});
      final data = Map<String, dynamic>.from(result.data);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF19111F),
          title: const Text(
            'رسالتك السرّية 💌',
            textAlign: TextAlign.center,
            style: TextStyle(color: pink),
          ),
          content: SingleChildScrollView(
            child: Text(
              data['message']?.toString() ?? '',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'تعذر فتح الرسالة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في الاتصال')),
      );
    }
  }

  void createMessage() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool sending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF19111F),
            title: const Text(
              'رسالتك السرّية 💌',
              textAlign: TextAlign.center,
              style: TextStyle(color: pink),
            ),
            content: TextField(
              controller: controller,
              maxLines: 5,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        final message = controller.text.trim();

                        if (message.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('اكتب الرسالة أولاً'),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => sending = true);

                        try {
                          final callable = FirebaseFunctions.instanceFor(
                            region: 'asia-east1',
                          ).httpsCallable('createSecret');

                          final result = await callable.call({
                            'message': message,
                          });

                          final data =
                              Map<String, dynamic>.from(result.data);
                          final code = data['code'].toString();

                          if (!mounted) return;

                          Navigator.pop(dialogContext);

                          showDialog(
                            context: context,
                            builder: (resultContext) => AlertDialog(
                              backgroundColor: const Color(0xFF19111F),
                              title: const Text(
                                'تم إنشاء رسالتك 💗',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: pink),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'هذا هو الرمز السرّي. أرسله للشخص الذي تريد أن يقرأ رسالتك:',
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 18),
                                  SelectableText(
                                    code,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: pink,
                                      fontSize: 19,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'صلاحية الرسالة: 24 ساعة',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(resultContext),
                                  child: const Text('حسناً'),
                                ),
                              ],
                            ),
                          );
                        } on FirebaseFunctionsException catch (e) {
                          setDialogState(() => sending = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.message ?? 'تعذر إنشاء الرسالة'),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => sending = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('حدث خطأ في الاتصال'),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: pink,
                  foregroundColor: Colors.white,
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('إنشاء الرمز'),
              ),
            ],
          ),
        );
      },
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarBackground()),
          Positioned(
            top: -100,
            left: -70,
            child: glow(230, purple),
          ),
          Positioned(
            bottom: -120,
            right: -70,
            child: glow(260, pink),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 20,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'S I R R',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 8,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: pink, blurRadius: 25),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'بعض الأسرار تستحق أن تبقى بين قلبين',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 35),
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Container(
                        height: 210,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF21112C),
                              Color(0xFF100D19),
                              Color(0xFF251022),
                            ],
                          ),
                          border: Border.all(
                            color: pink.withOpacity(0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: pink.withOpacity(
                                0.10 + animation.value * 0.12,
                              ),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Positioned(
                              top: 18,
                              child: Text(
                                'رسالة من القلب',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 45,
                              child: Icon(
                                Icons.mark_email_unread_rounded,
                                size: 65,
                                color: pink,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 90,
                              child: CustomPaint(
                                painter: CatPainter(animation.value),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'افتح رسالتك',
                    style: TextStyle(
                      fontSize: 23,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'أدخل الرمز السرّي الذي وصلك',
                    style: TextStyle(color: Colors.white54),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: codeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: 4,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      hintText: 'SIRR-XXXXXX',
                      hintStyle: const TextStyle(
                        color: Colors.white30,
                        letterSpacing: 3,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: purple.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: pink,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: openMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'فتح الرسالة  ♡',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextButton.icon(
                    onPressed: createMessage,
                    icon: const Icon(Icons.favorite, color: pink),
                    label: const Text(
                      'أنشئ رسالة سرّية',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'SIRR • عالم صغير لأسرارك',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget glow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.16),
              blurRadius: 100,
              spreadRadius: 35,
            ),
          ],
        ),
      ),
    );
  }
}

class StarBackground extends StatelessWidget {
  const StarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StarPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35);
    final random = math.Random(12);

    for (int i = 0; i < 65; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.3;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CatPainter extends CustomPainter {
  final double progress;

  CatPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFFC6E1)
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final x = 35 + (progress * 2 * size.width) % (size.width - 75);
    final y = size.height - 23;
    final bounce = math.sin(progress * math.pi * 12) * 2;

    canvas.save();
    canvas.translate(x, y + bounce);

    final tail = Path()
      ..moveTo(-13, -20)
      ..quadraticBezierTo(-34, -38, -24, -48);
    canvas.drawPath(tail, outline);

    canvas.drawOval(
      const Rect.fromLTWH(-22, -32, 40, 25),
      p,
    );

    canvas.drawCircle(const Offset(12, -36), 15, p);

    final ears = Path()
      ..moveTo(1, -45)
      ..lineTo(3, -60)
      ..lineTo(12, -48)
      ..moveTo(15, -49)
      ..lineTo(25, -60)
      ..lineTo(27, -43);

    canvas.drawPath(ears, p);
    canvas.drawPath(ears, outline);

    final eye = Paint()
      ..color = const Color(0xFF32162D)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(const Offset(7, -37), 1.8, eye);
    canvas.drawCircle(const Offset(18, -37), 1.8, eye);
    canvas.drawCircle(const Offset(13, -31), 1.5, eye);

    canvas.drawLine(
      const Offset(-12, -12),
      Offset(-12, -2 + bounce),
      outline,
    );

    canvas.drawLine(
      const Offset(8, -12),
      Offset(8, -2 - bounce),
      outline,
    );

    if (progress > 0.55 && progress < 0.95) {
      final heart = Path()
        ..moveTo(48, -53)
        ..cubicTo(30, -68, 18, -48, 48, -28)
        ..cubicTo(78, -48, 66, -68, 48, -53)
        ..close();

      final heartPaint = Paint()
        ..color = pink
        ..style = PaintingStyle.fill;

      canvas.drawPath(heart, heartPaint);
      canvas.drawPath(heart, outline);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CatPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}