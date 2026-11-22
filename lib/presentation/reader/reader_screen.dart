import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/waraq_palette.dart';
import '../../core/widgets/document_cover.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/waraq_sheet.dart';
import '../../data/data_providers.dart';
import '../../data/pdf/pdf_page_cache.dart';
import '../../data/pdf/pdf_renderer.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/entities/reading_position.dart';
import '../providers/bookmark_providers.dart';
import '../providers/library_providers.dart';
import '../providers/settings_providers.dart';
import 'reader_controller.dart';
import 'widgets/auto_scroll_sheet.dart';
import 'widgets/bookmarks_sheet.dart';
import 'widgets/display_sheet.dart';
import 'widgets/pages_sheet.dart';
import '../widgets/note_editor_sheet.dart';
import 'widgets/reader_canvas.dart';
import 'widgets/reader_chrome.dart';

/// Full-screen reading surface: canvas plus floating chrome.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({required this.document, this.startPage, super.key});

  final PdfDocument document;

  /// Opens the document on this page instead of the saved position.
  final int? startPage;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with TickerProviderStateMixin {
  PdfRenderer? _renderer;
  ReaderController? _controller;
  Object? _error;
  int _prepared = 0;
  int _total = 0;
  bool _opening = true;
  bool _systemUiHidden = false;
  int _toolIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    PdfRenderer? renderer;
    try {
      renderer = await PdfRenderer.open(
        widget.document.filePath,
        onProgress: (int done, int total) {
          if (!mounted) {
            return;
          }
          setState(() {
            _prepared = done;
            _total = total;
          });
        },
      );
      if (!mounted) {
        await renderer.dispose();
        return;
      }

      final AppSettings settings = ref.read(settingsProvider);
      Map<String, ReadingPosition> positions = const <String, ReadingPosition>{};
      try {
        positions = await ref.read(positionsProvider.future);
      } catch (_) {
        // A missing position just means "start from the beginning".
      }

      final ReaderController controller = ReaderController(
        document: widget.document,
        renderer: renderer,
        cache: PdfPageCache(renderer: renderer),
        readingState: ref.read(readingStateRepositoryProvider),
        initialSettings: settings.reader,
        initialPosition: positions[widget.document.id],
        startPage: widget.startPage,
        vsync: this,
      );
      controller.addListener(_handleChromeChange);

      setState(() {
        _renderer = renderer;
        _controller = controller;
        _opening = false;
        _error = null;
      });

      unawaited(
        ref.read(documentsProvider.notifier).markOpened(widget.document.id),
      );
    } catch (error) {
      await renderer?.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _opening = false;
      });
    }
  }

  void _handleChromeChange() {
    final ReaderController? controller = _controller;
    if (controller == null) {
      return;
    }
    final bool hide = !controller.chromeVisible;
    if (hide == _systemUiHidden) {
      return;
    }
    _systemUiHidden = hide;
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        hide ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ),
    );
  }

  void _close() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _opening = true;
      _prepared = 0;
      _total = 0;
    });
    unawaited(_open());
  }

  void _persistReaderDefaults() {
    final ReaderController? controller = _controller;
    if (controller == null) {
      return;
    }
    unawaited(
      ref
          .read(settingsProvider.notifier)
          .updateReader((_) => controller.settingsSnapshot),
    );
  }

  Future<void> _toggleBookmark() async {
    final ReaderController? controller = _controller;
    if (controller == null) {
      return;
    }
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool added = await ref.read(bookmarksProvider.notifier).toggle(
          documentId: widget.document.id,
          page: controller.currentPage,
        );
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(added ? strings.bookmarkAdded : strings.bookmarkRemoved),
          duration: Duration(milliseconds: added ? 4000 : 1500),
          action: added
              ? SnackBarAction(
                  label: strings.noteAddAction,
                  onPressed: () => unawaited(_editNoteForCurrentPage()),
                )
              : null,
        ),
      );
  }

  /// Writes (or edits) the note of the page currently on screen.
  Future<void> _editNoteForCurrentPage() async {
    final ReaderController? controller = _controller;
    if (controller == null) {
      return;
    }
    final int page = controller.currentPage;
    String? existing;
    List<String> existingTags = const <String>[];
    for (final Bookmark bookmark
        in ref.read(documentBookmarksProvider(widget.document.id))) {
      if (bookmark.page == page) {
        existing = bookmark.note;
        existingTags = bookmark.tagIds;
        break;
      }
    }
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Bookmark? saved = await showNoteEditor(
      context,
      documentId: widget.document.id,
      page: page,
      pageCount: controller.pageCount,
      initialNote: existing,
      initialTags: existingTags,
    );
    if (saved != null) {
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(strings.noteSaved)));
    }
  }

  Future<void> _openTool(int index) async {
    final ReaderController? controller = _controller;
    if (controller == null) {
      return;
    }
    setState(() => _toolIndex = index);
    try {
      if (index == 0) {
        await showWaraqSheet<void>(
          context: context,
          builder: (BuildContext context) => PagesSheet(controller: controller),
        );
      } else if (index == 1) {
        await showWaraqSheet<void>(
          context: context,
          builder: (BuildContext context) => BookmarksSheet(
            controller: controller,
            document: widget.document,
          ),
        );
      } else if (index == 2) {
        await showWaraqSheet<void>(
          context: context,
          builder: (BuildContext context) => AutoScrollSheet(
            controller: controller,
            onSpeedCommitted: (double _) => _persistReaderDefaults(),
          ),
        );
      } else if (index == 3) {
        await showWaraqSheet<void>(
          context: context,
          builder: (BuildContext context) => DisplaySheet(
            controller: controller,
            onChanged: _persistReaderDefaults,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _toolIndex = 0);
      }
    }
  }

  @override
  void dispose() {
    final ReaderController? controller = _controller;
    if (controller != null) {
      controller.removeListener(_handleChromeChange);
      controller.dispose();
    }
    final PdfRenderer? renderer = _renderer;
    if (renderer != null) {
      unawaited(renderer.dispose());
    }
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ReaderController? controller = _controller;
    final WaraqPalette palette = WaraqPalette.of(context);

    if (_error != null) {
      return _ReaderErrorView(onBack: _close, onRetry: _retry);
    }
    if (_opening || controller == null) {
      return _PreparingView(
        document: widget.document,
        prepared: _prepared,
        total: _total,
        onBack: _close,
      );
    }

    final List<Bookmark> bookmarks =
        ref.watch(documentBookmarksProvider(widget.document.id));

    return Scaffold(
      backgroundColor: palette.readerBackdrop,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: ReaderCanvas(controller: controller)),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: controller,
                builder: (BuildContext context, Widget? child) {
                  return ColoredBox(
                    color: Colors.black.withFraction(controller.dim),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: controller,
              builder: (BuildContext context, Widget? child) {
                bool bookmarked = false;
                for (final Bookmark bookmark in bookmarks) {
                  if (bookmark.page == controller.currentPage) {
                    bookmarked = true;
                    break;
                  }
                }
                return ReaderChrome(
                  controller: controller,
                  document: widget.document,
                  bookmarked: bookmarked,
                  selectedTool: _toolIndex,
                  onBack: _close,
                  onToggleBookmark: () => unawaited(_toggleBookmark()),
                  onToolSelected: (int index) => unawaited(_openTool(index)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreparingView extends StatelessWidget {
  const _PreparingView({
    required this.document,
    required this.prepared,
    required this.total,
    required this.onBack,
  });

  final PdfDocument document;
  final int prepared;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              top: Gap.xs,
              start: Gap.xs,
              child: IconButton(
                onPressed: onBack,
                tooltip: strings.back,
                icon: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(Gap.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DocumentCover(document: document, width: 88, height: 118),
                    const SizedBox(height: Gap.xl),
                    Text(
                      document.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: Gap.s),
                    Text(
                      strings.preparingPages,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Gap.l),
                    SizedBox(
                      width: 180,
                      child: LinearProgressIndicator(
                        value: total > 0
                            ? (prepared / total).clamp(0.0, 1.0).toDouble()
                            : null,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                    ),
                    const SizedBox(height: Gap.m),
                    Text(
                      total > 0 ? '$prepared / $total' : '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: Gap.m),
                    Text(
                      strings.preparingPagesHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withFraction(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderErrorView extends StatelessWidget {
  const _ReaderErrorView({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              top: Gap.xs,
              start: Gap.xs,
              child: IconButton(
                onPressed: onBack,
                tooltip: strings.back,
                icon: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                ),
              ),
            ),
            Center(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: strings.documentErrorTitle,
                message: strings.documentErrorBody,
                action: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(strings.retry),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
