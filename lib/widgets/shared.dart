import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

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

/// A Forui button's label. Forui lays a label out in a row, where plain text
/// would run off a narrow button at large text sizes; this one wraps instead.
class ButtonLabel extends StatelessWidget {
  const ButtonLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Flexible(child: Text(text, textAlign: TextAlign.center));
}

/// A pushed page: a Forui header with a back button over a scrolling body.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          FHeader.nested(
            title: Text(title),
            prefixes: [
              FHeaderAction.back(
                // Forui's touch action is 44 pixels; two more on each side
                // meets the 48-pixel touch target.
                style: const .delta(padding: .add(.all(2))),
                onPress: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          Expanded(child: PageBody(children: children)),
        ],
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
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: theme.colors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.typography.display.lg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A server error with a way to retry.
class ServerError extends StatelessWidget {
  const ServerError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FAlert(
          variant: .destructive,
          icon: const Icon(Icons.error_outline),
          title: Text(message),
        ),
        const SizedBox(height: 8),
        FButton(
          variant: .outline,
          onPress: onRetry,
          child: const ButtonLabel('Try again'),
        ),
      ],
    ),
  );
}
