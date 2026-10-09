import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_colors.dart';
import '../../../models/sla_status.dart';

/// How the project splits across the four SLA states.
///
/// ## Why this is painted by hand
///
/// A charting package would give a pie with a drop shadow, a boxed legend and
/// a default palette that fights everything else on screen. This is a thin
/// ring in the app's own colours with the total set in the middle - closer to
/// a printed statistical graphic than to a dashboard widget.
///
/// The restraint is deliberate and is the whole point: no gridlines, no
/// shadow, no gradient, no 3D, no value labels crowding the arcs. The ring
/// carries the proportions, the legend underneath carries the exact numbers,
/// and neither repeats the other.
class SlaRingChart extends StatelessWidget {
  const SlaRingChart({super.key, required this.counts});

  /// Task count per SLA state, from `SlaService.summarise`.
  final Map<SlaStatus, int> counts;

  /// Worst first, so the eye meets the problem before the reassurance.
  static const List<SlaStatus> _order = [
    SlaStatus.overdue,
    SlaStatus.atRisk,
    SlaStatus.onTrack,
    SlaStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final total = counts.values.fold(0, (sum, value) => sum + value);

    final segments = <_Segment>[
      for (final status in _order)
        if ((counts[status] ?? 0) > 0)
          _Segment(
            value: counts[status]!,
            color: StatusColors.forSla(context, status).foreground,
          ),
    ];

    return Row(
      children: [
        SizedBox(
          height: 124,
          width: 124,
          child: CustomPaint(
            painter: _RingPainter(
              segments: segments,
              trackColor: c.surfaceMuted,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: AppTypography.metric.copyWith(
                      color: c.textPrimary,
                      fontSize: 30,
                    ),
                  ),
                  Text(
                    total == 1 ? 'task' : 'tasks',
                    style: AppTypography.badge.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final status in _order)
                _LegendRow(
                  status: status,
                  count: counts[status] ?? 0,
                  total: total,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment {
  const _Segment({required this.value, required this.color});

  final int value;
  final Color color;
}

/// Paints the ring.
///
/// A stroked arc rather than filled wedges: a thin ring reads as a proportion
/// without the heavy ink of a solid pie, and it leaves the middle free for the
/// total, which is the number people actually want.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.segments, required this.trackColor});

  final List<_Segment> segments;
  final Color trackColor;

  /// Thin enough to read as a line rather than as a donut.
  static const double _stroke = 10;

  /// A hairline of canvas between arcs, so neighbouring colours stay distinct
  /// without a white outline around every segment.
  static const double _gapRadians = 0.045;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = (math.min(size.width, size.height) - _stroke) / 2;
    final circle = Rect.fromCircle(center: centre, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = trackColor;

    // The track always draws, so an empty project still shows a ring rather
    // than collapsing to nothing and shifting the layout.
    canvas.drawCircle(centre, radius, track);

    final total = segments.fold(0, (sum, s) => sum + s.value);
    if (total == 0) return;

    // Start at twelve o'clock and run clockwise, the way a reader expects.
    var start = -math.pi / 2;
    final single = segments.length == 1;

    for (final segment in segments) {
      final sweep = (segment.value / total) * math.pi * 2;

      // Only inset a gap when there is more than one arc; a lone full circle
      // should close, not show a notch.
      final gap = single ? 0.0 : _gapRadians;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.butt
        ..color = segment.color;

      canvas.drawArc(
        circle,
        start + gap / 2,
        math.max(sweep - gap, 0.004),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.trackColor != trackColor ||
      old.segments.length != segments.length ||
      !_sameValues(old.segments, segments);

  static bool _sameValues(List<_Segment> a, List<_Segment> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}

/// One line of the legend: swatch, label, count, share.
///
/// Laid out as a small table rather than as free text - the counts right-align
/// into a column, which is what makes four rows scannable instead of four
/// sentences.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.status,
    required this.count,
    required this.total,
  });

  final SlaStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pair = StatusColors.forSla(context, status);
    final percent = total == 0 ? 0 : ((count / total) * 100).round();

    // A state with nothing in it stays on the list but recedes, so the four
    // rows do not reflow every time a task changes state.
    final muted = count == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: muted ? c.border : pair.foreground,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: muted ? c.textTertiary : c.textSecondary,
              ),
            ),
          ),
          Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: muted ? c.textTertiary : c.textPrimary,
              fontWeight: FontWeight.w600,
              // Tabular figures keep the counts in a straight column instead
              // of jittering as the digits change width.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              style: AppTypography.caption.copyWith(
                color: c.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
