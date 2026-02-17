import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    Get.offNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E17),
              const Color(0xFF151B2B),
              const Color(0xFF0A0E17),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background grid
            ...List.generate(20, (index) {
              return Positioned(
                left: (index % 5) * (MediaQuery.of(context).size.width / 5),
                top: (index ~/ 5) * (MediaQuery.of(context).size.height / 4),
                child:
                    Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFFF3366).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .fadeIn(duration: 2000.ms, delay: (index * 100).ms)
                        .fadeOut(
                          duration: 2000.ms,
                          delay: (2000 + index * 100).ms,
                        ),
              );
            }),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF3366),
                              const Color(0xFFFF3366).withOpacity(0.3),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3366).withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.radar,
                          size: 60,
                          color: Colors.white,
                        ),
                      )
                      .animate()
                      .scale(duration: 1000.ms, curve: Curves.elasticOut)
                      .then()
                      .shimmer(duration: 2000.ms, color: Colors.white),

                  const SizedBox(height: 40),

                  // App title
                  Text(
                        'SENTINEL',
                        style: GoogleFonts.orbitron(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                  Text(
                    'ROVER DEFENSE SYSTEM',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF00F5FF),
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 800.ms),

                  const SizedBox(height: 60),

                  // Loading indicator
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFFF3366),
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 1200.ms),

                  const SizedBox(height: 20),

                  Text(
                    'Initializing Defense Protocol...',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white30,
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 1500.ms),
                ],
              ),
            ),

            // Version info
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v1.0.0 | CLASSIFIED',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.2),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 2000.ms),
          ],
        ),
      ),
    );
  }
}
