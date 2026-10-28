import 'package:flutter/material.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: children,
      ),
    ),
  );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(message),
      ],
    ),
  );
}

class ServerError extends StatelessWidget {
  const ServerError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
