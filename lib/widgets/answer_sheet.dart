import 'package:flutter/material.dart';

class AnswerSheet extends StatelessWidget {
  final int questionCount;
  final int lettersPerQuestion;
  final Map<String, String> answers;
  final void Function(int questionIndex, String letter)? onSelect;

  const AnswerSheet({
    super.key,
    required this.questionCount,
    required this.lettersPerQuestion,
    required this.answers,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (questionCount <= 0 || lettersPerQuestion <= 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 420.0;
        final columns = width >= 860 ? 3 : (width >= 520 ? 2 : 1);
        final rowsPerColumn = (questionCount / columns).ceil();
        final columnWidth = width / columns;

        const numberWidth = 34.0;
        const gap = 8.0;
        const spacing = 6.0;
        final avail = columnWidth - numberWidth - gap * 2;
        final diameter =
            ((avail - spacing * (lettersPerQuestion - 1)) / lettersPerQuestion)
                .clamp(14.0, 30.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++)
              SizedBox(
                width: columnWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var r = 0; r < rowsPerColumn; r++)
                      _buildRow(
                        context,
                        c * rowsPerColumn + r,
                        diameter,
                        numberWidth,
                        gap,
                        spacing,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    int q,
    double diameter,
    double numberWidth,
    double gap,
    double spacing,
  ) {
    if (q >= questionCount) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = answers[q.toString()];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: numberWidth,
            child: Text(
              '${q + 1}'.padLeft(2, '0'),
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: gap),
          for (var j = 0; j < lettersPerQuestion; j++) ...[
            if (j > 0) const SizedBox(width: 6),
            _OptionCircle(
              letter: String.fromCharCode(65 + j),
              diameter: diameter,
              selected: selected == String.fromCharCode(65 + j),
              onTap: onSelect == null
                  ? null
                  : () => onSelect!(q, String.fromCharCode(65 + j)),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionCircle extends StatelessWidget {
  final String letter;
  final double diameter;
  final bool selected;
  final VoidCallback? onTap;

  const _OptionCircle({
    required this.letter,
    required this.diameter,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final circle = Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : null,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Text(
        letter,
        style: textTheme.labelSmall?.copyWith(
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.bold : FontWeight.w400,
        ),
      ),
    );

    if (onTap == null) return circle;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: circle,
    );
  }
}
