import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/utils/app_colors.dart';

const _kSky = AppColors.primary;
const _kSkyLight = Color.fromARGB(255, 239, 254, 255);

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Privacy Policy',
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
                  Icon(Icons.shield_outlined, size: 44.sp, color: AppColors.btnColor),
                  SizedBox(height: 12.h),
                  Text(
                    'Privacy Policy',
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
                    'We value your privacy and are committed to protecting your personal information. This Privacy Policy explains how Retro Route Co. collects, uses, discloses, and safeguards your information when you use our website (www.retrorouteco.com), mobile applications (iOS & Android), and delivery services.',
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
                  // ── Trust badges ────────────────────────────────────────
                  Row(
                    children: [
                      _TrustBadge(icon: Icons.lock_rounded, title: 'SSL Encrypted', desc: 'All data is encrypted'),
                      SizedBox(width: 10.w),
                      _TrustBadge(icon: Icons.visibility_off_rounded, title: 'No Data Selling', desc: 'We never sell your info'),
                      SizedBox(width: 10.w),
                      _TrustBadge(icon: Icons.verified_user_rounded, title: 'PIPEDA Compliant', desc: 'Canadian privacy law'),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // ── Information We Collect ───────────────────────────────
                  _SectionCard(
                    icon: Icons.storage_rounded,
                    title: 'Information We Collect',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubHeading(text: 'Personal Information You Provide'),
                        ...[
                          'Name, email address, phone number when you create an account',
                          'Shipping and billing addresses for order fulfillment and delivery zone assignment',
                          'Payment information processed securely through Stripe — we never store, process, or have access to your full card number, CVV, or expiry date on our servers',
                          'Email and push notification settings',
                          'Pool or hot tub type, volume (liters), sanitizer type (bromine/chlorine/salt), and last drain date — used to provide personalized water care recommendations',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 10.h),
                        _SubHeading(text: 'Water Test Data'),
                        _bodyText(
                            'When our driver visits your home, we collect water chemistry data from testing your pool or hot tub using a LaMotte WaterLink Spin Touch device. This includes up to 14 parameters:'),
                        SizedBox(height: 6.h),
                        _bodyText(
                            'Free Chlorine, Total Chlorine, Bromine, pH, Total Alkalinity, Calcium Hardness, Cyanuric Acid (CYA), Copper, Iron, Salt, Phosphate, Borate, Biguanide, and Biguanide Shock.'),
                        SizedBox(height: 6.h),
                        _bodyText(
                            'This data is used solely to generate accurate product recommendations for your water care needs and is stored in your account history for ongoing service improvement.'),
                        SizedBox(height: 10.h),
                        _SubHeading(text: 'Automatically Collected Information'),
                        ...[
                          'Device information: browser type, operating system, device model, app version',
                          'Usage data: pages visited, products viewed, search queries, app interactions',
                          'Cookies & local storage: used to remember your preferences, cart items, and login status',
                          'Firebase Cloud Messaging (FCM) tokens: stored to deliver push notifications to your device',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 10.h),
                        _SubHeading(text: 'Location Data'),
                        ...[
                          'Customer App: With your explicit consent, we collect approximate location data to determine your delivery zone across Eastern Ontario (Kingston to Brockville to Cornwall). We do NOT continuously track your location',
                          'Driver App: Precise GPS location is collected from driver devices during active delivery routes for real-time route optimization. Driver location is only collected during working hours and active deliveries',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 10.h),
                        _SubHeading(text: 'Delivery Documentation'),
                        _Bullet(text: 'Our driver may photograph the delivered products at your doorstep as proof of delivery. These photos are stored securely and associated with your order record'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── How We Use ───────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.person_rounded,
                    title: 'How We Use Your Information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...[
                          'Process and fulfill your orders — Website orders shipped via Canada Post or Purolator within Ontario; App orders via local milk run delivery across Eastern Ontario',
                          'Conduct water testing and generate personalized AutoCrate product recommendations',
                          'Assign you to a local delivery zone and milk run schedule (Zone 1 Monday: Brockville area, Zone 2 Tuesday: Smiths Falls area, Zone 3 Friday: Kingston area)',
                          'Send order confirmations, delivery updates, and push notifications via Firebase',
                          'Calculate pricing including HST (13% Ontario) and apply water test fees (\$39, waived with product purchase)',
                          'Improve our website, apps, and services based on usage patterns',
                          'Respond to your inquiries and provide customer support',
                          'Send promotional emails and push notifications (only with your consent)',
                          'Prevent fraud and ensure platform security',
                          'Track inventory across our 3-stage system (Warehouse → Trailer → Customer) using QR/barcode scanning',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Information Sharing ──────────────────────────────────
                  _SectionCard(
                    icon: Icons.language_rounded,
                    title: 'Information Sharing',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[600], height: 1.5),
                            children: [
                              const TextSpan(text: 'We '),
                              TextSpan(
                                text: 'do not sell, rent, or trade',
                                style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[900]),
                              ),
                              const TextSpan(
                                  text: ' your personal information to third parties for marketing or advertising purposes.'),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _bodyText('We may share information with the following service providers:'),
                        SizedBox(height: 8.h),
                        ...[
                          'Stripe — Payment processing (PCI-DSS compliant)',
                          'Canada Post / Purolator — Website order shipping (Ontario only)',
                          'Local Delivery Drivers — App-based milk run delivery (Eastern Ontario)',
                          'MongoDB Atlas — Database hosting (cloud)',
                          'Railway — Backend API hosting',
                          'Firebase (Google) — Push notifications, analytics',
                          'Cloudinary — Product image hosting (no personal data)',
                          'Vercel — Website and dashboard hosting',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 10.h),
                        _SubHeading(text: 'Data Residency'),
                        _bodyText(
                            'Our primary database is hosted on MongoDB Atlas. Data may be stored in data centres located in Canada and/or the United States. All cross-border transfers comply with PIPEDA requirements.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Data Security ────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.lock_rounded,
                    title: 'Data Security',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('We implement industry-standard security measures:'),
                        SizedBox(height: 10.h),
                        ...[
                          'SSL/TLS encryption for all data transmitted between your device and our servers',
                          'PCI-DSS compliant payment processing through Stripe',
                          'Encrypted database with MongoDB Atlas (encryption at rest and in transit)',
                          'Role-based access controls limiting employee access (Admin, Driver, Customer roles)',
                          'JWT secure token-based authentication for API access',
                          'Regular security testing and vulnerability assessments',
                          'Product barcodes and SKU identifiers visible only to Admin accounts, never to customers',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Data Retention ───────────────────────────────────────
                  _SectionCard(
                    icon: Icons.schedule_rounded,
                    title: 'Data Retention',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('We retain your personal information only as long as necessary:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Active Accounts: Data retained while your account is active',
                          'Order History: Retained for up to 7 years for Canadian tax/legal requirements (CRA)',
                          'Water Test History: Retained while your account is active for ongoing recommendations',
                          'Delivery Photos: Retained for 90 days after delivery, then automatically deleted',
                          'FCM Tokens: Updated or removed when you uninstall the app or revoke permissions',
                          'After Account Deletion: Personal data permanently removed; anonymized records may be retained for legal compliance',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Cookies & Notifications ─────────────────────────────
                  _SectionCard(
                    icon: Icons.notifications_rounded,
                    title: 'Cookies & Notifications',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubHeading(text: 'Cookies'),
                        ...[
                          'Remember your login status and session',
                          'Store cart items and shopping preferences',
                          'Track anonymized usage patterns to improve our service',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 6.h),
                        _bodyText('You can manage cookie preferences through your browser settings.'),
                        SizedBox(height: 10.h),
                        _SubHeading(text: 'Push Notifications'),
                        _bodyText('Push notifications are opt-in only. We use Firebase Cloud Messaging (FCM) to deliver:'),
                        SizedBox(height: 6.h),
                        ...[
                          'Order status updates',
                          'Delivery arrival notifications',
                          'Water test completion alerts',
                          'Promotional offers (only with separate consent)',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 6.h),
                        _bodyText('You can manage notification preferences in your Account Settings or device settings at any time.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Your Rights ──────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.assignment_ind_rounded,
                    title: 'Your Rights',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText(
                            'Under Canada\'s Personal Information Protection and Electronic Documents Act (PIPEDA), you have the right to:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Access the personal information we hold about you',
                          'Correct inaccurate or incomplete information',
                          'Delete your personal information (subject to legal retention obligations)',
                          'Withdraw consent for data collection at any time',
                          'Opt out of marketing communications and promotional notifications',
                          'Data portability — request a copy of your data in a commonly used format',
                          'File a complaint with the Office of the Privacy Commissioner of Canada (www.priv.gc.ca)',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 6.h),
                        _bodyText('To exercise any of these rights, contact our Privacy Officer. We will respond within 30 days.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Account Deletion ─────────────────────────────────────
                  _SectionCard(
                    icon: Icons.delete_forever_rounded,
                    title: 'Account Deletion',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('You have the right to delete your account and all associated personal data at any time.'),
                        SizedBox(height: 10.h),
                        _SubHeading(text: 'How to delete your account:'),
                        ...[
                          '1. Open the Retro Route Co. app',
                          '2. Go to Settings → Account → Delete Account',
                          '3. Confirm your decision',
                          '4. Your personal profile data will be permanently removed within 30 days',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 8.h),
                        _bodyText('Alternatively, email our Privacy Officer at Admin@retrorouteco.com. Upon deletion:'),
                        SizedBox(height: 6.h),
                        ...[
                          'Your personal profile, address, and contact information will be permanently removed',
                          'Order records may be retained in anonymized form for up to 7 years for legal/tax compliance',
                          'Water test history associated with your account will be deleted',
                          'Any pending orders will be cancelled',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── No Sale of Data ──────────────────────────────────────
                  _SectionCard(
                    icon: Icons.block_rounded,
                    title: 'No Sale of Data',
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[600], height: 1.5),
                            children: [
                              TextSpan(
                                text: 'Retro Route Co. does not sell, rent, or trade your personal information ',
                                style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[900]),
                              ),
                              const TextSpan(
                                  text: 'to third parties for marketing or advertising purposes. We only share data with service providers necessary to deliver our products and services. This applies to all users regardless of location.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Inclusivity ──────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.diversity_3_rounded,
                    title: 'Our Commitment to Inclusivity',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText(
                            'Retro Route Co. is committed to providing a welcoming, respectful, and inclusive experience for all customers, regardless of race, ethnicity, national origin, gender identity, gender expression, sexual orientation, age, disability, religion, or any other characteristic protected under Canadian law.'),
                        SizedBox(height: 8.h),
                        _bodyText(
                            'We proudly serve all communities across Eastern Ontario. Our services, pricing, delivery schedules, and product recommendations are provided equally to every customer.'),
                        SizedBox(height: 8.h),
                        _bodyText(
                            'If you experience or witness any form of discrimination, please contact us at Admin@retrorouteco.com.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Accessibility ────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.accessible_rounded,
                    title: 'Accessibility',
                    child: Column(
                      children: [
                        _bodyText(
                            'Retro Route Co. is committed to meeting the requirements of the Accessibility for Ontarians with Disabilities Act (AODA). We strive to ensure our website, mobile apps, and services are accessible to all individuals. If you experience any accessibility barriers, please contact us and we will provide an alternative format.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Children's Privacy ───────────────────────────────────
                  _SectionCard(
                    icon: Icons.child_care_rounded,
                    title: "Children's Privacy",
                    child: Column(
                      children: [
                        _bodyText(
                            'Retro Route Co. services are not directed to individuals under the age of 18. We do not knowingly collect personal information from children. If you believe a child has provided us with personal information, please contact our Privacy Officer and we will promptly investigate and delete the information.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Water Testing Disclaimer ─────────────────────────────
                  _SectionCard(
                    icon: Icons.science_rounded,
                    title: 'Water Testing & Product Recommendations Disclaimer',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText(
                            'Water testing uses the LaMotte WaterLink Spin Touch device. Results and AutoCrate recommendations are provided for informational purposes only and should not be considered professional chemical engineering or health advice.'),
                        SizedBox(height: 10.h),
                        ...[
                          'Results may vary based on sample collection, environmental conditions, and equipment calibration',
                          'Product recommendations are automated and may not account for all variables unique to your pool or hot tub',
                          'Retro Route Co. is not responsible for any damage or injury resulting from the use of recommended products',
                          'Always read and follow product label instructions before use',
                          'For complex water chemistry issues, consult a certified pool and spa professional',
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
                              const TextSpan(
                                  text: 'Keep all chemicals out of reach of children, never mix chemicals together, and always follow manufacturer dosage instructions.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Limitation of Liability ──────────────────────────────
                  _SectionCard(
                    icon: Icons.gavel_rounded,
                    title: 'Limitation of Liability',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText(
                            'To the fullest extent permitted by the laws of Ontario and Canada, Retro Route Co. shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Use of our water testing services or product recommendations',
                          'Application or misapplication of products purchased through our services',
                          'Delivery delays, service interruptions, or scheduling changes',
                          'Errors or inaccuracies in water test results',
                          'Loss of data or unauthorized access to your account',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 6.h),
                        _bodyText(
                            'Our total liability for any claim shall not exceed the amount you paid to Retro Route Co. in the twelve (12) months preceding the claim.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Indemnification ──────────────────────────────────────
                  _SectionCard(
                    icon: Icons.security_rounded,
                    title: 'Indemnification',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText(
                            'You agree to indemnify, defend, and hold harmless Retro Route Co. from any claims, damages, losses, liabilities, and expenses arising from:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Your use of our products or services',
                          'Your violation of this Privacy Policy or any applicable law',
                          'Any third-party claim related to the use or misuse of products delivered to you',
                          'Any inaccurate or incomplete information you provide to us',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Warranty Disclaimer ──────────────────────────────────
                  _SectionCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Warranty Disclaimer',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText(
                            'Our services, including water testing, product recommendations, and delivery, are provided on an "as-is" and "as-available" basis. Retro Route Co. makes no warranties, express or implied, regarding:'),
                        SizedBox(height: 10.h),
                        ...[
                          'The accuracy, completeness, or reliability of water test results',
                          'The suitability of recommended products for your specific situation',
                          'Uninterrupted or error-free service availability',
                          'The condition of products upon delivery (beyond manufacturer packaging)',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 6.h),
                        _bodyText('This does not affect your statutory rights under Canadian consumer protection laws.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Consent to Delivery Documentation ────────────────────
                  _SectionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Consent to Delivery Documentation',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('By using our delivery services, you consent to our drivers photographing delivered products as proof of delivery. These photos:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Capture only the delivered products and immediate delivery area (e.g., doorstep)',
                          'Are not intended to capture personal or private areas of your property',
                          'Are stored securely and retained for 90 days for dispute resolution',
                          'Are accessible only by authorized Retro Route Co. staff',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 6.h),
                        _bodyText('If you do not wish to have delivery photos taken, please inform your driver or contact us in advance.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Data Breach Notification ─────────────────────────────
                  _SectionCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Data Breach Notification',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('In the event of a data breach involving your personal information, Retro Route Co. will:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Notify the Office of the Privacy Commissioner of Canada as required under PIPEDA',
                          'Notify affected individuals as soon as feasible, no later than 72 hours after becoming aware',
                          'Provide details of the breach, steps we are taking, and steps you can take to protect yourself',
                          'Maintain a record of all data breaches for a minimum of 24 months',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── CASL Compliance ──────────────────────────────────────
                  _SectionCard(
                    icon: Icons.email_rounded,
                    title: 'Canada\'s Anti-Spam Legislation (CASL)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('We comply with CASL. We will only send commercial electronic messages if:'),
                        SizedBox(height: 10.h),
                        ...[
                          'You have provided explicit or implied consent',
                          'Each message identifies Retro Route Co. as the sender',
                          'Each message includes a clear and easy unsubscribe mechanism',
                          'Unsubscribe requests are processed within 10 business days',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 6.h),
                        _bodyText('You can withdraw your consent at any time through your account settings or by contacting Admin@retrorouteco.com.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Third-Party Links ────────────────────────────────────
                  _SectionCard(
                    icon: Icons.link_rounded,
                    title: 'Third-Party Links',
                    child: Column(
                      children: [
                        _bodyText(
                            'Our website and apps may contain links to third-party websites or services. Retro Route Co. is not responsible for the privacy practices, content, or security of any third-party websites. We encourage you to review their privacy policies.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Users Outside Ontario ────────────────────────────────
                  _SectionCard(
                    icon: Icons.public_rounded,
                    title: 'Users Outside Ontario',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('Retro Route Co. services are primarily designed for residents of Ontario, Canada. If you access our services from outside Ontario:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Your information will be processed in accordance with Ontario and Canadian law',
                          'You consent to the transfer and processing of your data in Canada',
                          'Local laws in your jurisdiction may differ from Canadian privacy laws',
                          'We make no representation that our services are appropriate outside Ontario',
                        ].map((s) => _Bullet(text: s)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Force Majeure ────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.bolt_rounded,
                    title: 'Force Majeure',
                    child: Column(
                      children: [
                        _bodyText(
                            'Retro Route Co. shall not be liable for any failure or delay in performing our obligations due to circumstances beyond our reasonable control, including natural disasters, severe weather, pandemics, government orders, supply chain disruptions, labour disputes, power outages, or internet service interruptions.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Governing Law ────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.balance_rounded,
                    title: 'Governing Law & Dispute Resolution',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText(
                            'This Privacy Policy is governed by the laws of the Province of Ontario and the federal laws of Canada. Any disputes shall first be attempted to be resolved through good faith negotiation. If unresolved within 30 days, either party may pursue resolution through the courts of Ontario. You agree to the exclusive jurisdiction of the courts in Brockville, Ontario.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Severability ─────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.rule_rounded,
                    title: 'Severability',
                    child: Column(
                      children: [
                        _bodyText(
                            'If any provision of this Privacy Policy is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Changes ──────────────────────────────────────────────
                  _SectionCard(
                    icon: Icons.update_rounded,
                    title: 'Changes to This Policy',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bodyText('We may update this Privacy Policy from time to time. We will notify you via:'),
                        SizedBox(height: 10.h),
                        ...[
                          'Email notification to your registered email address',
                          'In-app notification',
                          'A prominent notice on our website',
                        ].map((s) => _Bullet(text: s)),
                        SizedBox(height: 6.h),
                        _bodyText('Continued use of our services after changes constitutes acceptance of the updated policy.'),
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
                          'Privacy Officer: Muhammad Shahroz Ayub\nEmail: Admin@retrorouteco.com\nPhone: 438-462-3477\nAddress: 1111 Development Dr,\nBrockville, ON K6V 7G2, Canada',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 13.sp, color: Colors.grey[700], height: 1.6),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Office of the Privacy Commissioner of Canada\nwww.priv.gc.ca | 1-800-282-1376',
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

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _TrustBadge({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: _kSkyLight,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Icon(icon, size: 20.sp, color: _kSky),
            ),
            SizedBox(height: 8.h),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.grey[900])),
            SizedBox(height: 2.h),
            Text(desc,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }
}

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
