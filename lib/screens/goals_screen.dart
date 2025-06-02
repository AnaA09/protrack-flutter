import 'package:flutter/material.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGoalCard(
            context,
            'Career Goal',
            'Lead Developer',
            'Become a Lead Developer within 2 years',
            DateTime.now().add(const Duration(days: 730)),
            0.6,
          ),
          _buildGoalCard(
            context,
            'Skill Development',
            'Cloud Architecture',
            'Master AWS and Azure cloud architecture',
            DateTime.now().add(const Duration(days: 365)),
            0.3,
          ),
          _buildGoalCard(
            context,
            'Certification',
            'PMP Certification',
            'Obtain Project Management Professional certification',
            DateTime.now().add(const Duration(days: 180)),
            0.8,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    String category,
    String title,
    String description,
    DateTime targetDate,
    double progress,
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
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Target: ${targetDate.day}/${targetDate.month}/${targetDate.year}',
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
