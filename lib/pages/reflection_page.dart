import 'dart:async';

import 'package:flutter/material.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:diary/l10n/app_localizations.dart';

import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import 'drawing_editor.dart';

class ReflectionPage extends StatefulWidget {
  const ReflectionPage({super.key});

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> {
  final _storage = StorageService();
  late Future<List<DiaryEntry>> _future;
  final PageController _pageController = PageController();
  Timer? _timer;
  StreamSubscription<void>? _sub;
  // 選択中の振り返り対象の年月（1日固定）
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _future = _storage.loadEntries();
    // 初期呼び出しは itemCount を知らないのでデフォルト動作（何もしない）
    _startAutoPlay();
    // 追加/削除などの保存完了を購読して即時再読込
    _sub = _storage.changes.listen((_) async {
      if (!mounted) return;
      setState(() {
        _future = _storage.loadEntries();
      });
      // 読み直し後にページインジケータと自動再生を調整
      final list = await _future;
      final filtered = _filterByMonth(list, _selectedMonth);
      if (!mounted) return;
      if (filtered.length <= 1) {
        _timer?.cancel();
      } else {
        _startAutoPlay(filtered.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  // 変更: itemCount を受け取り、1 以下なら自動再生を行わない。末尾到達時は 0 に戻る。
  void _startAutoPlay([int itemCount = 0]) {
    _timer?.cancel();
    if (itemCount <= 1) return; // 0 または 1 のときは自動再生しない

    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      final pc = _pageController;
      if (!pc.hasClients) return;

      // 現在ページ（整数）を計算して次ページを itemCount で巡回
      final currentPage = pc.page != null ? pc.page!.round() : pc.initialPage;
      final next = (currentPage + 1) % itemCount;

      pc.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _storage.loadEntries();
    });
    await _future;
  }

  List<DiaryEntry> _filterByMonth(List<DiaryEntry> all, DateTime ym) {
    return all.where((e) {
      return e.date.year == ym.year &&
          e.date.month == ym.month &&
          e.drawingJson != null &&
          e.drawingJson!.trim().isNotEmpty;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _pickMonth() async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('月を選択'),
          content: SizedBox(
            width: 360,
            height: 360,
            child: MonthPicker(
              initialDate: DateTime(
                _selectedMonth.year,
                _selectedMonth.month,
                1,
              ),
              minDate: DateTime(2000, 1, 1),
              maxDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
              onDateSelected: (d) => Navigator.of(context).pop(d),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
    if (result != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(result.year, result.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.reflectionTitle(_selectedMonth.year, _selectedMonth.month),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _pickMonth,
              icon: const Icon(Icons.calendar_month),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<DiaryEntry>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final entries = _filterByMonth(snap.data!, _selectedMonth);

          // エントリー取得後のフレームでタイマーを開始/停止（build 中の副作用を避ける）
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (entries.length <= 1) {
              _timer?.cancel();
            } else {
              _startAutoPlay(entries.length);
            }
          });

          if (entries.isEmpty) {
            return Center(child: Text(t.emptyEntries));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final squareSize =
                                      constraints.biggest.shortestSide;
                                  return Center(
                                    child: SizedBox(
                                      width: squareSize,
                                      height: squareSize,
                                      child: DrawingThumbnail(
                                        drawingJson: e.drawingJson!,
                                        backgroundColor: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        size: squareSize,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${e.date.year}/${e.date.month}/${e.date.day}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Text(
                                e.content,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                    onPageChanged: (i) {},
                  ),
                ),
                const SizedBox(height: 8),
                // Indicator
                FutureBuilder<List<DiaryEntry>>(
                  future: _future,
                  builder: (context, s2) {
                    final total = entries.length;
                    return SizedBox(
                      height: 36,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(total, (i) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double selectedness = 0.0;
                              if (_pageController.hasClients &&
                                  _pageController.page != null) {
                                selectedness =
                                    (1 -
                                    ((_pageController.page! - i).abs()).clamp(
                                      0.0,
                                      1.0,
                                    ));
                              } else {
                                selectedness =
                                    (_pageController.initialPage == i)
                                    ? 1.0
                                    : 0.0;
                              }
                              final color = Color.lerp(
                                Colors.grey,
                                Theme.of(context).colorScheme.primary,
                                selectedness,
                              )!;
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}
