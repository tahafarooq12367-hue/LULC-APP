import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/result_model.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatefulWidget {
  final ResultModel result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _touchedIndex = -1;

  // Assign a distinct color per class slot
  static const List<Color> _palette = [
    AppTheme.midGreen,
    AppTheme.oceanBlue,
    AppTheme.skyBlue,
    AppTheme.accentGold,
    AppTheme.earthBrown,
    AppTheme.lightGreen,
    AppTheme.forestGreen,
    AppTheme.deepOcean,
    AppTheme.sandTan,
    AppTheme.lightSky,
  ];

  Color _colorFor(int index) => _palette[index % _palette.length];

  @override
  Widget build(BuildContext context) {
    final results = widget.result.topResults;
    final label = widget.result.label;
    final confidence = widget.result.confidence;
    final mainColor =
        AppTheme.classColors[label] ?? AppTheme.midGreen;
    final mainIcon =
        AppTheme.classIcons[label] ?? Icons.landscape_rounded;

    return Scaffold(
      appBar: AppBar(
        title: Text('Result',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Main result card ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: mainColor.withValues(alpha: 0.4)),
              ),
              child: Column(children: [
                Icon(mainIcon, color: mainColor, size: 56),
                const SizedBox(height: 14),
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text('${confidence.toStringAsFixed(1)}% confidence',
                    style: GoogleFonts.outfit(
                        fontSize: 15, color: AppTheme.textSecondary)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: confidence / 100,
                    minHeight: 10,
                    backgroundColor: AppTheme.cardBorder,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(mainColor),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 28),

            if (results.isNotEmpty) ...[
              // ── Pie chart ─────────────────────────────────────────────
              Text('Distribution',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(children: [
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection ==
                                      null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sectionsSpace: 3,
                        centerSpaceRadius: 48,
                        sections: List.generate(results.length, (i) {
                          final isTouched = i == _touchedIndex;
                          final r = results[i];
                          return PieChartSectionData(
                            value: r.confidence,
                            color: _colorFor(i),
                            radius: isTouched ? 68 : 56,
                            title: isTouched
                                ? '${r.confidence.toStringAsFixed(1)}%'
                                : '',
                            titleStyle: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(results.length, (i) {
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: _colorFor(i),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(results[i].label,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ]);
                    }),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Bar chart ─────────────────────────────────────────────
              Text('Confidence Scores',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      maxY: 100,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${results[group.x].label}\n',
                              GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                              children: [
                                TextSpan(
                                  text:
                                      '${rod.toY.toStringAsFixed(1)}%',
                                  style: GoogleFonts.outfit(
                                      color: _colorFor(group.x),
                                      fontSize: 12),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}%',
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i >= results.length) {
                                return const SizedBox.shrink();
                              }
                              // Shorten long labels
                              final lbl = results[i].label.length > 8
                                  ? '${results[i].label.substring(0, 7)}…'
                                  : results[i].label;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(lbl,
                                    style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary)),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppTheme.cardBorder,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(results.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: results[i].confidence,
                              color: _colorFor(i),
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Top predictions list ───────────────────────────────────
              Text('Top Predictions',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              ...List.generate(results.length, (i) {
                final r = results[i];
                final c = _colorFor(i);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: c, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(r.label,
                            style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text('${r.confidence.toStringAsFixed(1)}%',
                          style: GoogleFonts.outfit(
                              color: c,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
