import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safeguard/widgets/bubble_background.dart';
import 'package:safeguard/services/analytics_service.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Resources'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: BubbleBackground()),
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emergency,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Emergency Resources',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quick access to emergency services and safety information',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Safety Tips Section
              Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              const SafetyTipCard(
                title: 'Be Aware of Your Surroundings',
                tip:
                    'Avoid distractions like your phone or headphones. Pay attention to the people and environment around you.',
                icon: Icons.visibility,
              ),
              const SafetyTipCard(
                title: 'Trust Your Instincts',
                tip:
                    'If a situation or person feels unsafe, it probably is. Remove yourself from the situation immediately.',
                icon: Icons.psychology,
              ),
              const SafetyTipCard(
                title: 'Share Your Plans',
                tip:
                    'Let a friend or family member know where you are going and when you expect to be back.',
                icon: Icons.share_location,
              ),

              const SizedBox(height: 24),

              // Emergency Numbers Section
              Text(
                'Emergency Hotlines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              EmergencyNumberTile(
                label: 'Police Emergency',
                number: '119',
                icon: Icons.local_police,
                color: Colors.blue,
                description: 'For immediate police assistance',
              ),
              EmergencyNumberTile(
                label: 'Ambulance (Suwaseriya)',
                number: '1990',
                icon: Icons.medical_services,
                color: Colors.red,
                description: 'Medical emergency services',
              ),
              EmergencyNumberTile(
                label: 'Fire & Rescue',
                number: '110',
                icon: Icons.fire_truck,
                color: Colors.orange,
                description: 'Fire and rescue services',
              ),
              EmergencyNumberTile(
                label: 'Disaster Management',
                number: '117',
                icon: Icons.warning,
                color: Colors.amber,
                description: 'Natural disaster assistance',
              ),
              EmergencyNumberTile(
                label: 'Women & Children Help Desk',
                number: '1938',
                icon: Icons.child_care,
                color: Colors.purple,
                description: 'Support for women and children',
              ),
              EmergencyNumberTile(
                label: 'Mental Health (National)',
                number: '1926',
                icon: Icons.psychology,
                color: Colors.green,
                description: 'Mental health support',
              ),

              const SizedBox(height: 24),

              // Additional Resources
              Text(
                'Additional Resources',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              const SafetyTipCard(
                title: 'In an Emergency',
                tip:
                    'Call 119 or 1990 immediately. Share your live location using this app when safe to do so.',
                icon: Icons.emergency_share,
              ),

              // Quick Actions
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.location_on,
                              label: 'Share Location',
                              color: Theme.of(context).colorScheme.primary,
                              onTap: () {
                                AnalyticsService.logUserEngagement(
                                  'share_location_clicked',
                                );
                                // TODO: Implement location sharing
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.contacts,
                              label: 'Emergency Contacts',
                              color: Theme.of(context).colorScheme.primary,
                              onTap: () {
                                AnalyticsService.logUserEngagement(
                                  'emergency_contacts_clicked',
                                );
                                // TODO: Navigate to emergency contacts
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyTipCard extends StatelessWidget {
  final String title;
  final String tip;
  final IconData icon;

  const SafetyTipCard({
    super.key,
    required this.title,
    required this.tip,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmergencyNumberTile extends StatelessWidget {
  final String label;
  final String number;
  final IconData icon;
  final Color color;
  final String description;

  const EmergencyNumberTile({
    super.key,
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _call(number, label),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.call,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _call(String number, String service) async {
    try {
      AnalyticsService.logCustomEvent('emergency_call_attempted', {
        'service': service,
        'number': number,
      });

      final Uri callUri = Uri.parse('tel:$number');
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
        AnalyticsService.logCustomEvent('emergency_call_launched', {
          'service': service,
          'number': number,
        });
      } else {
        AnalyticsService.logCustomEvent('emergency_call_failed', {
          'service': service,
          'number': number,
          'reason': 'cannot_launch_url',
        });
      }
    } catch (e) {
      AnalyticsService.recordError(e, null);
    }
  }
}
