import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:footprint3/login_page.dart';
import 'package:footprint3/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class FootprintLandingPage extends StatelessWidget {
  const FootprintLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Footprint - Document Tracking System',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 218, 173, 147), Color(0xFFFBE6DA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 800;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLeftContent(context, isMobile),
                            const SizedBox(height: 30),
                            _buildRightImage(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildLeftContent(context, isMobile)),
                            Expanded(child: _buildRightImage()),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLeftContent(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FOOTPRINT',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isMobile ? 36 : 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Document Tracking That’s Fast & Reliable",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Footprint document tracking system offers automated alerts and thorough audit trail logging, Palawan State University's Taytay Campus effectively manages and secures data.",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: isMobile ? 16 : 18,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(
                  "Download",
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final Uri url = Uri.parse('https://drive.google.com/file/d/1l8tEmZ1ElxxBOV4hVsUQvitpfVtlYWcD/view?usp=sharing');
                    if (!await launchUrl(url)) {
                      print('Error launching URL');
                    }
                },
              ),
              Container(
                height: 40,
                child: ElevatedButton(
                  child: Text(
                    "Use in Browser",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: mainOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildRightImage() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: SvgPicture.asset(
        'images/Illustration.svg',
      ),
    );
  }
}
