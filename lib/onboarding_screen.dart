import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'auth_gate.dart'; // Halaman tujuan kita setelah selesai

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  bool _isLastPage = false;

  Future<void> _onDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. PAGE VIEW (Layar Geser)
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _isLastPage = (index == 2);
              });
            },
            children: [
              _buildPage(
                imagePath: 'assets/splashscreen/SPLASH SCREEN 1.png',
              ),
              _buildPage(
                imagePath: 'assets/splashscreen/SPLASH SCREEN 2.png',
              ),
              _buildPage(
                imagePath: 'assets/splashscreen/SPLASH SCREEN 3.png',
              ),
            ],
          ),

          // 2. TOMBOL "SKIP"
          if (!_isLastPage)
            Positioned(
              top: 50.0,
              right: 20.0,
              child: TextButton(
                onPressed: _onDone, 
                child: const Text(
                  'Skip',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),

          // --- (PERUBAHAN UTAMA DI SINI) ---
          // 3. KONTROL BAWAH (DOTS + TOMBOL)
          Positioned(
            bottom: 40.0, // Jarak dari bawah
            left: 20.0,   // Jarak dari kiri
            right: 20.0,  // Jarak dari kanan
            // Ganti Row menjadi Column
            child: Column( 
              children: [
                // 3a. Indikator Titik (Dots)
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: ExpandingDotsEffect(
                    activeDotColor: Theme.of(context).colorScheme.primary,
                    dotColor: Colors.grey[300]!,
                    dotHeight: 10,
                    dotWidth: 10,
                  ),
                ),

                const SizedBox(height: 24.0), // Jarak antara dots dan tombol

                // 3b. Tombol Next / Get Started (dibuat lebar penuh)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_isLastPage) {
                        _onDone();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      // Buat tombol lebih bulat seperti di gambar
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0), 
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 14.0), // Sedikit lebih tinggi
                    ),
                    child: Text(
                      _isLastPage ? 'Mulai Sekarang' : 'Lanjut',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- (AKHIR PERUBAHAN) ---
        ],
      ),
    );
  }

  // Widget helper untuk membuat 1 halaman
  Widget _buildPage({required String imagePath}) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}