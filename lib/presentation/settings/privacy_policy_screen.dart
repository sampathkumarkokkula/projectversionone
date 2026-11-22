import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows the bundled privacy policy (PRIVACY_POLICY.md at the repo root).
///
/// A small renderer for the Markdown subset the policy uses: headings,
/// paragraphs, "-" / "*" lists, **bold** and tables. Each table row is shown
/// as a card (column name: value), which stays readable on a phone screen.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('PRIVACY_POLICY.md'),
        builder: (context, snapshot) {
          final text = snapshot.data;
          if (text == null) return const Center(child: CircularProgressIndicator());
          final blocks = parsePolicyMarkdown(text);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: blocks.length,
            itemBuilder: (context, i) => _BlockView(blocks[i]),
          );
        },
      ),
    );
  }
}

sealed class PolicyBlock {
  const PolicyBlock();
}

class PolicyHeading extends PolicyBlock {
  const PolicyHeading(this.level, this.text);
  final int level;
  final String text;
}

class PolicyParagraph extends PolicyBlock {
  const PolicyParagraph(this.text);
  final String text;
}

class PolicyBullet extends PolicyBlock {
  const PolicyBullet(this.text);
  final String text;
}

class PolicyTable extends PolicyBlock {
  const PolicyTable(this.header, this.rows);
  final List<String> header;
  final List<List<String>> rows;
}

List<String> _cells(String line) {
  var s = line.trim();
  if (s.startsWith('|')) s = s.substring(1);
  if (s.endsWith('|')) s = s.substring(0, s.length - 1);
  return [for (final c in s.split('|')) c.trim()];
}

bool _isTableSeparator(String line) => RegExp(r'^\s*\|?\s*:?-{3,}').hasMatch(line);

/// Splits the policy into blocks. Lines of a paragraph or list item are
/// joined, as Markdown does.
List<PolicyBlock> parsePolicyMarkdown(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blocks = <PolicyBlock>[];
  final buffer = StringBuffer();
  var bullet = false;

  void flush() {
    final text = buffer.toString().trim();
    if (text.isNotEmpty) blocks.add(bullet ? PolicyBullet(text) : PolicyParagraph(text));
    buffer.clear();
    bullet = false;
  }

  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trim();
    final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
    if (trimmed.isEmpty) {
      flush();
    } else if (heading != null) {
      flush();
      blocks.add(PolicyHeading(heading.group(1)!.length, heading.group(2)!.trim()));
    } else if (trimmed.startsWith('|') && i + 1 < lines.length && _isTableSeparator(lines[i + 1])) {
      flush();
      final header = _cells(trimmed);
      final rows = <List<String>>[];
      i += 2;
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        rows.add(_cells(lines[i]));
        i++;
      }
      blocks.add(PolicyTable(header, rows));
      continue;
    } else if (RegExp(r'^[-*]\s+').hasMatch(trimmed)) {
      flush();
      bullet = true;
      buffer.write(trimmed.replaceFirst(RegExp(r'^[-*]\s+'), ''));
    } else {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(trimmed);
    }
    i++;
  }
  flush();
  return blocks;
}

/// **bold** spans; everything else is plain text.
TextSpan _inline(String text, TextStyle? style) {
  final spans = <TextSpan>[];
  final bold = RegExp(r'\*\*(.+?)\*\*');
  var start = 0;
  for (final m in bold.allMatches(text)) {
    if (m.start > start) spans.add(TextSpan(text: text.substring(start, m.start)));
    spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w600)));
    start = m.end;
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return TextSpan(style: style, children: spans);
}

class _BlockView extends StatelessWidget {
  const _BlockView(this.block);

  final PolicyBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return switch (block) {
      PolicyHeading(:final level, text: final t) => Padding(
          padding: EdgeInsets.only(top: level == 1 ? 8 : 20, bottom: 8),
          child: Text(t, style: level == 1 ? text.headlineSmall : text.titleMedium),
        ),
      PolicyParagraph(text: final t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text.rich(_inline(t, text.bodyMedium)),
        ),
      PolicyBullet(text: final t) => Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: text.bodyMedium),
              Expanded(child: Text.rich(_inline(t, text.bodyMedium))),
            ],
          ),
        ),
      PolicyTable(:final header, :final rows) => Column(
          children: [
            for (final row in rows)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (row.isNotEmpty) Text.rich(_inline(row.first, text.titleSmall)),
                      for (var c = 1; c < row.length; c++)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c < header.length)
                                Text(header[c], style: text.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                              Text.rich(_inline(row[c], text.bodyMedium)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
    };
  }
}
