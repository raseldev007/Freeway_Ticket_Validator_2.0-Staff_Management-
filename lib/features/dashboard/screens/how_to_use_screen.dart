import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/trip_provider.dart';

class HowToUseScreen extends StatefulWidget {
  const HowToUseScreen({super.key});

  @override
  State<HowToUseScreen> createState() => _HowToUseScreenState();
}

class _HowToUseScreenState extends State<HowToUseScreen> {
  bool _isEnglish = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final canVerify = provider.canVerify;
    final canManage = provider.canManage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEnglish ? 'How to Use' : 'ব্যবহার বিধি',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          _buildLanguageToggle(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildTopBanner(),
            const SizedBox(height: 20),
            _buildStep(
              title: _isEnglish ? 'Staff Login' : 'স্টাফ লগইন',
              description: _isEnglish
                  ? 'Enter your registered mobile number to receive a 5-digit OTP. If the code doesn\'t arrive, use the "Resend" option.'
                  : 'আপনার নিবন্ধিত মোবাইল নম্বরটি লিখুন এবং ৫-ডিজিটের OTP সংগ্রহ করুন। কোডটি না আসলে "Resend" অপশনটি ব্যবহার করুন।',
              icon: Icons.vpn_key_rounded,
              iconColor: Colors.teal,
              bgColor: const Color(0xFFF0FDFA),
            ),
            _buildStep(
              title: _isEnglish ? 'Select Your Trip' : 'ট্রিপ নির্বাচন করুন',
              description: _isEnglish
                  ? 'From the dashboard, you will see a list of assigned trips. Tap on a Trip to enter the verification area.'
                  : 'ড্যাশবোর্ড থেকে আপনার নির্ধারিত ট্রিপের তালিকা দেখতে পাবেন। ভেরিফিকেশন শুরু করতে একটি ট্রিপে ট্যাপ করুন।',
              icon: Icons.directions_bus_rounded,
              iconColor: AppColors.primary,
              bgColor: const Color(0xFFFFF5F5),
            ),
            if (canManage)
              _buildStep(
                title: _isEnglish ? 'Trip Assignment' : 'ট্রিপ অ্যাসাইনমেন্ট',
                description: _isEnglish
                    ? 'Open "Manage Trip" to assign staff and vehicle. Search for Driver/Helper by name or EMP-ID. For vehicles, search by Coach Number or Manufacturer (e.g. Scania, Hino), select, and tap Save.'
                    : '"Manage Trip" অপশনে গিয়ে স্টাফ ও গাড়ি এসাইন করুন। ড্রাইভার/হেল্পারকে নাম বা EMP-ID দিয়ে এবং গাড়িকে কোচ নম্বর অথবা কোম্পানি (যেমন- Scania, Hino) লিখে সার্চ করে তালিকা থেকে সিলেক্ট করুন এবং "Save" বাটনে ট্যাপ করে সম্পন্ন করুন।',
                icon: Icons.assignment_ind_rounded,
                iconColor: Colors.indigo,
                bgColor: const Color(0xFFEEF2FF),
              ),
            if (canVerify) ...[
              _buildStep(
                title: _isEnglish ? 'Passenger Directory' : 'যাত্রী তালিকা',
                description: _isEnglish
                    ? 'Inside a trip, tap "Passenger List" to see all bookings, seat numbers, and boarding status (Verified/Pending).'
                    : 'ট্রিপের ভিতরে, সকল বুকিং, সিট নম্বর এবং বোর্ডিং স্ট্যাটাস (Verified/Pending) দেখতে "Passenger List"-এ ট্যাপ করুন।',
                icon: Icons.groups_rounded,
                iconColor: Colors.orange,
                bgColor: const Color(0xFFFFF7ED),
              ),
              _buildStep(
                title: _isEnglish ? 'Quick QR Scan' : 'দ্রুত QR স্ক্যান',
                description: _isEnglish
                    ? 'Tap the "Scan QR" button and point your camera at the passenger\'s ticket. It will instantly verify and show seat info.'
                    : '"Scan QR" বাটনে ট্যাপ করুন এবং যাত্রীর টিকিটের দিকে ক্যামেরা ধরুন। এটি তাৎক্ষণিকভাবে ভেরিফাই করে সিটের তথ্য প্রদর্শন করবে।',
                icon: Icons.qr_code_scanner_rounded,
                iconColor: Colors.deepPurple,
                bgColor: const Color(0xFFF5F3FF),
              ),
              _buildStep(
                title: _isEnglish ? 'Manual Entry (PNR & PIN)' : 'ম্যানুয়াল এন্ট্রি (PNR এবং PIN)',
                description: _isEnglish
                    ? 'If scanning fails, enter the PNR and the 4-digit Secret PIN. If the passenger doesn\'t have the PIN, use the "Resend PIN" button.'
                    : 'যদি স্ক্যান কাজ না করে, তবে PNR এবং ৪-ডিজিটের Secret PIN প্রদান করুন। যাত্রীর কাছে PIN না থাকলে "Resend PIN" বাটন ব্যবহার করুন।',
                icon: Icons.app_registration_rounded,
                iconColor: Colors.blue,
                bgColor: const Color(0xFFEFF6FF),
              ),
              _buildStep(
                title: _isEnglish ? 'Boarding Success' : 'সফল বোর্ডিং',
                description: _isEnglish
                    ? 'A green screen confirms a valid ticket. You can then proceed to the next passenger or view trip summary.'
                    : 'সবুজ স্ক্রিন মানে টিকিটটি সঠিক। এরপর আপনি পরবর্তী যাত্রীর দিকে যেতে পারেন বা ট্রিপের সারসংক্ষেপ দেখতে পারেন।',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
                bgColor: const Color(0xFFF0FDF4),
              ),
            ],
            _buildStep(
              title: _isEnglish ? 'Seamless In-App Updates' : 'অ্যাপ আপডেট',
              description: _isEnglish
                  ? 'To ensure the highest security standards and real-time data accuracy, the app requires mandatory optimization. When an update prompt appears, click "Update" to synchronize. Access will be restricted until the update is finalized to prevent data inconsistency.'
                  : 'নিরাপত্তা নিশ্চিত করতে এবং সঠিক তথ্যের জন্য অ্যাপটি নিয়মিত আপডেট রাখা প্রয়োজন। আপডেটের নোটিফিকেশন আসলে "Update"-এ ক্লিক করে সিঙ্ক্রোনাইজ করুন। আপডেট শেষ না হওয়া পর্যন্ত অ্যাপের অ্যাক্সেস সীমিত থাকতে পারে।',
              icon: Icons.published_with_changes_rounded,
              iconColor: Colors.blueAccent,
              bgColor: const Color(0xFFE0F2FE),
            ),
            const SizedBox(height: 10),
            _buildTipsSection(canVerify),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            child: Text(
              _isEnglish ? 'Got it' : 'বুঝেছি',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('EN', _isEnglish),
          _buildLanguageOption('BN', !_isEnglish),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _isEnglish = label == 'EN';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Freeway Validator 2.0',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isEnglish ? 'Follow these steps for quick verification' : 'দ্রুত যাচাইকরণের জন্য এই ধাপগুলো অনুসরণ করুন',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection(bool canVerify) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.orange, size: 22),
              const SizedBox(width: 8),
              Text(
                _isEnglish ? 'Pro Tips' : 'প্রো টিপস',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildTipItem(_isEnglish
              ? 'Stable internet is required for real-time validation.'
              : 'রিয়েল-টাইম ভেরিফিকেশনের জন্য স্থিতিশীল ইন্টারনেট সংযোগ প্রয়োজন।'),
          if (canVerify) ...[
            _buildTipItem(_isEnglish
                ? 'Secret PIN is sent to the passenger via SMS during booking.'
                : 'বুকিংয়ের সময় যাত্রীকে SMS-এর মাধ্যমে Secret PIN পাঠানো হয়।'),
            _buildTipItem(_isEnglish
                ? 'If PIN is missing, use the "Resend PIN" button on the manual screen.'
                : 'যদি PIN না থাকে, তবে ম্যানুয়াল স্ক্রিনে "Resend PIN" বাটনটি ব্যবহার করুন।'),
            _buildTipItem(_isEnglish
                ? 'Keep the camera lens clean for faster QR scanning.'
                : 'দ্রুত QR স্ক্যান করার জন্য ক্যামেরার লেন্স পরিষ্কার রাখুন।'),
          ],
          _buildTipItem(_isEnglish
              ? 'Note: The app will cease to function if mandatory updates are not installed when prompted.'
              : 'দ্রষ্টব্য: অনুরোধ করার পর বাধ্যতামূলক আপডেটগুলি ইনস্টল না করা হলে অ্যাপটি কাজ করা বন্ধ করে দেবে।'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
