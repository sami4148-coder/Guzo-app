import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Frequently Asked Questions
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I cancel or modify my booking?',
      'answer': 'You can cancel or modify your booking by going to the "Trips" tab, selecting the reservation, and clicking "Manage Booking". Cancellations made 48 hours before check-in are fully refundable.',
    },
    {
      'question': 'What is the refund policy?',
      'answer': 'Refund policies vary by property. Most hotels offer a full refund if canceled 48 hours prior to check-in. Please check the specific cancellation policy on the hotel details page before booking.',
    },
    {
      'question': 'How do I contact the hotel directly?',
      'answer': 'Once your booking is confirmed, you will receive a confirmation email containing the hotel\'s direct phone number and email address. You can also find this information in the "Trips" tab.',
    },
    {
      'question': 'Can I pay at the property?',
      'answer': 'Yes, many of our partner hotels offer a "Pay at Property" option. You can select this during checkout if it is available for your chosen stay.',
    },
    {
      'question': 'How do I list my property on GUZO?',
      'answer': 'If you want to host guests, you can register a new account and select "Hotel Owner" as your role. You will then have access to the Owner Dashboard to list your property.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter FAQs based on search
    final filteredFaqs = _faqs.where((faq) {
      final question = faq['question']!.toLowerCase();
      final answer = faq['answer']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return question.contains(query) || answer.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: GuzoColors.ink),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(
            color: GuzoColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 28),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildSectionTitle('Frequently Asked Questions'),
          const SizedBox(height: 16),
          if (filteredFaqs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No results found. Try a different keyword.',
                  style: TextStyle(color: GuzoColors.muted),
                ),
              ),
            )
          else
            ...filteredFaqs.map((faq) => _buildFaqItem(faq['question']!, faq['answer']!)),
          
          const SizedBox(height: 32),
          _buildContactSection(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: GuzoColors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'SUPPORT',
            style: TextStyle(
              color: GuzoColors.green,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'How can we help\nyou today?',
          style: TextStyle(
            color: GuzoColors.ink,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Search Bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECEB)),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.ink.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search for answers...',
          hintStyle: const TextStyle(color: GuzoColors.muted, fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: GuzoColors.muted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Quick Actions (Top FAQs shortcut)
  // ─────────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            icon: Icons.calendar_month_rounded,
            title: 'Bookings',
            color: const Color(0xFF2E86AB),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            icon: Icons.payments_rounded,
            title: 'Payments',
            color: GuzoColors.green,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            icon: Icons.security_rounded,
            title: 'Account',
            color: const Color(0xFF8E6BBF),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6ECEB)),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: GuzoColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FAQ Accordion Item
  // ─────────────────────────────────────────────────────────────
  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECEB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          iconColor: GuzoColors.green,
          collapsedIconColor: GuzoColors.muted,
          title: Text(
            question,
            style: const TextStyle(
              color: GuzoColors.ink,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                color: GuzoColors.muted,
                fontSize: 13.5,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Contact Support Section
  // ─────────────────────────────────────────────────────────────
  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GuzoColors.green,
            GuzoColors.green.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.green.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Still need help?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is available 24/7 to assist you with any questions or issues.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // Action to open email or chat
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: GuzoColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.email_outlined, size: 20),
              label: const Text(
                'Contact Support',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Section Title Helper
  // ─────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: GuzoColors.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: GuzoColors.ink,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}