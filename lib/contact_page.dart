import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuka link: $url"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, child) {
        final currentTheme = AppTheme.currentTheme;

        return Theme(
          data: currentTheme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isNeo = modeIndex == 1;
              final isLight = theme.brightness == Brightness.light;

              final primaryColor = theme.colorScheme.primary;
              final secondaryColor = theme.colorScheme.secondary;
              final surfaceColor = theme.colorScheme.surface;
              final textColor = theme.colorScheme.onSurface;
              final subTextColor = textColor.withOpacity(0.7);

              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    "Customer Service",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                ),
                body: BackgroundWrapper(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header Icon Container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: isNeo
                                  ? Border.all(color: Colors.black, width: 2.5)
                                  : null,
                              boxShadow: isNeo
                                  ? [
                                      const BoxShadow(
                                        color: Colors.black,
                                        offset: Offset(4, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.4),
                                        blurRadius: 20,
                                      ),
                                    ],
                            ),
                            child: Icon(
                              Icons.support_agent_rounded,
                              size: 60,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Need Help?",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Contact us through our social media platforms below.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Contact Buttons List
                          Column(
                            children: [
                              _buildContactButton(
                                label: "Telegram Developer",
                                icon: FontAwesomeIcons.telegram,
                                color: secondaryColor,
                                url: "https://t.me/Virzofc",
                                theme: theme,
                                isNeo: isNeo,
                                textColor: textColor,
                              ),
                              const SizedBox(height: 16),
                              _buildContactButton(
                                label: "Telegram Support",
                                icon: FontAwesomeIcons.telegram,
                                color: secondaryColor,
                                url: "https://t.me/hyrinestur",
                                theme: theme,
                                isNeo: isNeo,
                                textColor: textColor,
                              ),
                              const SizedBox(height: 16),
                              _buildContactButton(
                                label: "Telegram Channel",
                                icon: FontAwesomeIcons.telegram,
                                color: secondaryColor,
                                url: "https://t.me/AllinformationVirz",
                                theme: theme,
                                isNeo: isNeo,
                                textColor: textColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContactButton({
    required String label,
    required IconData icon,
    required Color color,
    required String url,
    required ThemeData theme,
    required bool isNeo,
    required Color textColor,
  }) {
    final borderRadius = BorderRadius.circular(isNeo ? 8 : 16);

    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: borderRadius,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: borderRadius,
          border: Border.all(
            color: isNeo
                ? Colors.black
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isNeo ? 3.0 : 1.0,
          ),
          boxShadow: isNeo
              ? [
                  const BoxShadow(
                    color: Colors.black,
                    blurRadius: 0,
                    offset: Offset(4, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: isNeo
                        ? Border.all(color: Colors.black, width: 1.5)
                        : null,
                  ),
                  child: FaIcon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 20),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
