import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/utils/app_colors.dart';

const _kSky = AppColors.primary;
const _kSkyLight = Color.fromARGB(255, 239, 254, 255);

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
              color: _kSky,
              child: Column(
                children: [
                  Icon(Icons.description_outlined, size: 44.sp, color: AppColors.btnColor),
                  SizedBox(height: 12.h),
                  Text(
                    'Terms of Service',
                    style: GoogleFonts.inter(
                        fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Retro Route Co.',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'These Terms of Service govern your use of our website, mobile applications, and all related services. By accessing or using our services, you agree to be bound by these Terms.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFFe0f2fe), height: 1.5),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Acceptance of Terms ───────────────────────────────
                  _SectionCard(
                    icon: Icons.handshake_rounded,
                    title: '1. Acceptance of Terms',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('By creating an account, placing an order, or using any Retro Route Co. service, you confirm that:'),
                        SizedBox(height: 10.h),
                        ...[
                          'You are at least 18 years of age',
                          'You are a resident of Ontario, Canada (for local delivery services)',
                          'You have read and agree to these Terms and our Privacy Policy',
                          'You have the legal authority to enter into this agreement',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 2. Our Services ──────────────────────────────────────
                  _SectionCard(
                    icon: Icons.local_shipping_rounded,
                    title: '2. Our Services',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('Retro Route Co. provides:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Website (www.retrorouteco.com): Online sale and shipping of pool and hot tub chemicals and supplies within Ontario via Canada Post and Purolator',
                          'Mobile Apps (iOS & Android): Local delivery via our scheduled milk run route service across Eastern Ontario — Kingston to Brockville (main hub) to Cornwall and all communities in between',
                          'Water Testing: On-site water testing using LaMotte WaterLink Spin Touch devices, with automated product recommendations (AutoCrate)',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 3. Account Registration ──────────────────────────────
                  _SectionCard(
                    icon: Icons.person_add_rounded,
                    title: '3. Account Registration',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...[
                          'You must provide accurate, complete, and current information when creating an account',
                          'You are responsible for maintaining the confidentiality of your account credentials',
                          'You are responsible for all activities that occur under your account',
                          'Notify us immediately at info@retrorouteco.com if you suspect unauthorized access',
                          'We reserve the right to suspend or terminate accounts that violate these Terms',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 4. Delivery Zones & Scheduling ───────────────────────
                  _SectionCard(
                    icon: Icons.map_rounded,
                    title: '4. Delivery Zones & Scheduling',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubHeading(text: 'Local Delivery (App Orders)'),
                        ...[
                          'Zone 1 (Monday & Thursday): Brockville area and surrounding',
                          'Zone 2 (Tuesday): Smiths Falls area and surrounding',
                          'Zone 3 (Wednesday & Friday): Kingston area and surrounding',
                          'Covering all communities between Kingston and Cornwall',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 8.h),
                        _bodyText('To know the accurate route and schedule, please download our app — Retro Route Co. — available on Google Play Store and Apple App Store.'),
                        SizedBox(height: 10.h),
                        _SubHeading(text: 'Website Orders'),
                        ...[
                          'Shipped via Canada Post or Purolator within Ontario only',
                          'Estimated delivery times are provided at checkout and are not guaranteed',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 8.h),
                        _bodyText('We reserve the right to modify delivery zones, schedules, and shipping carriers at any time with reasonable notice.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 5. Pricing & Payment ─────────────────────────────────
                  _SectionCard(
                    icon: Icons.payments_rounded,
                    title: '5. Pricing & Payment',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...[
                          'All prices are in Canadian Dollars (CAD) and are subject to change without notice',
                          'HST (13%) is applied to all orders in accordance with Ontario tax law',
                          'Payment methods accepted: Credit/debit card (Visa, Mastercard, Amex) via Stripe',
                          'Water testing carries a \$39.00 visit fee, credited towards any chemical or supply purchase during the same visit',
                          'We reserve the right to correct pricing errors and cancel orders placed at incorrect prices',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 6. Water Testing Services ────────────────────────────
                  _SectionCard(
                    icon: Icons.science_rounded,
                    title: '6. Water Testing Services',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...[
                          'Water testing is performed by our trained drivers using LaMotte WaterLink Spin Touch devices',
                          'Test results and product recommendations (AutoCrate) are provided for informational purposes only',
                          'We do not guarantee the accuracy, completeness, or suitability of water test results or product recommendations',
                          'Water test results should not replace professional assessment for complex water chemistry issues',
                          'By requesting water testing, you authorize our driver to collect a water sample from your pool or hot tub',
                          'Water test data is stored in your account for ongoing service (see Privacy Policy)',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 7. Product Information & Safety ──────────────────────
                  _SectionCard(
                    icon: Icons.health_and_safety_rounded,
                    title: '7. Product Information & Safety',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...[
                          'All products sold by Retro Route Co. are manufactured by CAPO Industries (Burlington, Ontario) and branded as Retro Route Co.',
                          'Product descriptions, images, and specifications are provided for informational purposes and may vary slightly from actual products',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 8.h),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[600], height: 1.5),
                            children: [
                              TextSpan(
                                text: 'Chemical products can be hazardous if misused. ',
                                style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[900]),
                              ),
                              const TextSpan(text: 'Always read and follow product label instructions.'),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...[
                          'Never mix different chemical products together',
                          'Keep all chemicals out of reach of children and pets',
                          'Store chemicals in a cool, dry place away from direct sunlight',
                          'Retro Route Co. is not responsible for injury, damage, or loss resulting from improper use, storage, or handling of products',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 8. Returns, Refunds & Cancellations ──────────────────
                  _SectionCard(
                    icon: Icons.assignment_return_rounded,
                    title: '8. Returns, Refunds & Cancellations',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('All returns are subject to our Return Policy. Key points:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Chemical products are ALL SALES FINAL — no returns, exchanges, or refunds due to health, safety, and regulatory requirements',
                          'Non-chemical products: May be returned within 15 days if unopened and unused',
                          'Damaged/defective products: Report within 48 hours for replacement or refund',
                          'Water testing services: Non-refundable once performed',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 9. Intellectual Property ─────────────────────────────
                  _SectionCard(
                    icon: Icons.copyright_rounded,
                    title: '9. Intellectual Property',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...[
                          'All content on our website and apps (including logos, designs, text, graphics, software, and code) is the property of Retro Route Co. and is protected by Canadian and international intellectual property laws',
                          'All technology, software, and systems are the exclusive intellectual property of the Tech Co-Founder and are licensed for use by Retro Route Co.',
                          'You may not reproduce, distribute, modify, or create derivative works from any content without written permission',
                          'The Retro Route Co. name, logo, and branding are trademarks of Retro Route Co.',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 10. User Conduct ─────────────────────────────────────
                  _SectionCard(
                    icon: Icons.rule_rounded,
                    title: '10. User Conduct',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('You agree NOT to:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Use our services for any unlawful purpose',
                          'Provide false or misleading information',
                          'Attempt to gain unauthorized access to our systems, accounts, or data',
                          'Interfere with or disrupt our services or servers',
                          'Use automated systems (bots, scrapers) to access our services without permission',
                          'Resell products purchased through our services without authorization',
                          'Harass, threaten, or discriminate against our staff, drivers, or other customers',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 11. Limitation of Liability ──────────────────────────
                  _SectionCard(
                    icon: Icons.gavel_rounded,
                    title: '11. Limitation of Liability',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('To the fullest extent permitted by Ontario and Canadian law, Retro Route Co. shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Use of our products or services',
                          'Water test results or product recommendations',
                          'Delivery delays or service interruptions',
                          'Errors in pricing, product descriptions, or availability',
                          'Loss of data or unauthorized account access',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 6.h),
                        _bodyText('Our total liability for any claim shall not exceed the amount you paid to Retro Route Co. in the twelve (12) months preceding the claim.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 12. Indemnification ──────────────────────────────────
                  _SectionCard(
                    icon: Icons.security_rounded,
                    title: '12. Indemnification',
                    child: Column(
                      children: [
                        _bodyText('You agree to indemnify and hold harmless Retro Route Co., its officers, directors, employees, and agents from any claims, damages, losses, and expenses arising from your use of our services, violation of these Terms, or misuse of products purchased from us.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 13. Warranty Disclaimer ──────────────────────────────
                  _SectionCard(
                    icon: Icons.info_outline_rounded,
                    title: '13. Warranty Disclaimer',
                    child: Column(
                      children: [
                        _bodyText('Our services are provided on an "as-is" and "as-available" basis. We make no warranties, express or implied, regarding the accuracy of water test results, suitability of product recommendations, or uninterrupted service availability. This does not affect your statutory rights under Canadian consumer protection laws.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 14. Force Majeure ────────────────────────────────────
                  _SectionCard(
                    icon: Icons.bolt_rounded,
                    title: '14. Force Majeure',
                    child: Column(
                      children: [
                        _bodyText('We shall not be liable for delays or failures in performance due to circumstances beyond our reasonable control, including natural disasters, severe weather, pandemics, government orders, supply chain disruptions, labour disputes, or internet service interruptions.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 15. Privacy ──────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.privacy_tip_rounded,
                    title: '15. Privacy',
                    child: Column(
                      children: [
                        _bodyText('Your use of our services is also governed by our Privacy Policy, which describes how we collect, use, and protect your personal information. By using our services, you consent to our data practices as described in the Privacy Policy.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 16. Modifications to Terms ───────────────────────────
                  _SectionCard(
                    icon: Icons.update_rounded,
                    title: '16. Modifications to Terms',
                    child: Column(
                      children: [
                        _bodyText('We may update these Terms at any time. We will notify you of significant changes via email or in-app notification. Continued use of our services after changes constitutes acceptance of the updated Terms. We encourage you to review these Terms periodically.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 17. Termination ──────────────────────────────────────
                  _SectionCard(
                    icon: Icons.cancel_rounded,
                    title: '17. Termination',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...[
                          'You may close your account at any time through Settings → Account → Delete Account in the app, or by contacting us',
                          'We may suspend or terminate your account if you violate these Terms',
                          'Upon termination, your right to use our services ceases immediately',
                          'Sections that by their nature should survive termination (including Limitation of Liability, Indemnification, and Governing Law) will remain in effect',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 18. Governing Law ────────────────────────────────────
                  _SectionCard(
                    icon: Icons.balance_rounded,
                    title: '18. Governing Law & Dispute Resolution',
                    child: Column(
                      children: [
                        _bodyText('These Terms are governed by the laws of the Province of Ontario and the federal laws of Canada. Any disputes shall first be attempted to be resolved through good faith negotiation. If unresolved within 30 days, either party may pursue resolution through the courts located in Brockville, Ontario, Canada.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 19. Severability ─────────────────────────────────────
                  _SectionCard(
                    icon: Icons.rule_folder_rounded,
                    title: '19. Severability',
                    child: Column(
                      children: [
                        _bodyText('If any provision of these Terms is found to be unenforceable, that provision shall be limited to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 20. Entire Agreement ─────────────────────────────────
                  _SectionCard(
                    icon: Icons.article_rounded,
                    title: '20. Entire Agreement',
                    child: Column(
                      children: [
                        _bodyText('These Terms, together with our Privacy Policy and Return Policy, constitute the entire agreement between you and Retro Route Co. regarding the use of our services.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── 21. Inclusivity ──────────────────────────────────────
                  _SectionCard(
                    icon: Icons.diversity_3_rounded,
                    title: '21. Our Commitment to Inclusivity',
                    child: Column(
                      children: [
                        _bodyText('Retro Route Co. is committed to providing a welcoming, respectful, and inclusive experience for all customers, regardless of race, ethnicity, national origin, gender identity, gender expression, sexual orientation, age, disability, religion, or any other characteristic protected under the Canadian Human Rights Act and the Ontario Human Rights Code.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── Contact ──────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: _kSkyLight,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.contact_mail_rounded, size: 28.sp, color: _kSky),
                        SizedBox(height: 8.h),
                        Text(
                          'Contact Us',
                          style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800]),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Retro Route Co.\nEmail: info@retrorouteco.com\nPhone: 613-929-5522\nAddress: 1111 Development Dr,\nBrockville, ON K6V 7G2, Canada',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 13.sp, color: Colors.grey[700], height: 1.6),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Sales & General Inquiries: info@retrorouteco.com\nPrivacy & Legal: Admin@retrorouteco.com\nPrivacy Officer: Muhammad Shahroz Ayub',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 12.sp, color: Colors.grey[500], height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),
                  Center(
                    child: Text(
                      'Last updated: April 2026',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[800]),
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20.sp, color: _kSky),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900])),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: AppColors.cardBgColor.withOpacity(0.6), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SubHeading extends StatelessWidget {
  final String text;
  const _SubHeading({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey[900])),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h, right: 8.w),
            child: Container(
              width: 6.r,
              height: 6.r,
              decoration: const BoxDecoration(color: _kSky, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: Colors.grey[800], height: 1.5)),
          ),
        ],
      ),
    );
  }
}

Widget _bodyText(String text) => Text(
      text,
      style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[800], height: 1.5),
    );
