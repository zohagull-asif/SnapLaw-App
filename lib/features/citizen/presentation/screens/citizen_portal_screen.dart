import 'package:flutter/material.dart';
import 'citizen_guidance_screen.dart';
import 'citizen_justice_screen.dart';
import 'citizen_quiz_screen.dart';
import 'citizen_faq_screen.dart';
import 'citizen_lawbot_screen.dart';
import 'citizen_safespeak_screen.dart';

class CitizenPortalScreen extends StatefulWidget {
  final int initialTab;
  const CitizenPortalScreen({super.key, this.initialTab = 0});

  @override
  State<CitizenPortalScreen> createState() => _CitizenPortalScreenState();
}

class _CitizenPortalScreenState extends State<CitizenPortalScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  static const List<Widget> _screens = [
    CitizenGuidanceScreen(),
    CitizenJusticeScreen(),
    CitizenQuizScreen(),
    CitizenFaqScreen(),
    CitizenLawBotScreen(),
    CitizenSafeSpeakScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.balance, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('SnapLaw Citizen Portal',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF1A3A5C),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back to Home',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A3A5C),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white54,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'My Rights'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Justice'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'FAQs'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'LawBot AI'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'SafeSpeak'),
        ],
      ),
    );
  }
}
