import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProgressCard(
            context,
            'Career Growth',
            'Senior Developer',
            'Promoted to Senior Developer position',
            DateTime.now().subtract(const Duration(days: 7)),
          ),
          _buildProgressCard(
            context,
            'Skills',
            'Flutter Development',
            'Completed Advanced Flutter Course',
            DateTime.now().subtract(const Duration(days: 14)),
          ),
          _buildProgressCard(
            context,
            'Certifications',
            'AWS Certified',
            'Obtained AWS Solutions Architect Certification',
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    String category,
    String title,
    String description,
    DateTime date,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Achieved on ${date.day}/${date.month}/${date.year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
