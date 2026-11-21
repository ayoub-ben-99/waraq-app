import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/waraq_palette.dart';
import '../../../core/widgets/pop_icon.dart';
import '../../../domain/entities/pdf_document.dart';
import '../reader_controller.dart';
import 'page_scrubber.dart';

/// Everything that floats above the page: the top bar, the bottom tool dock,
/// the page indicator and the immersive progress hairline.
class ReaderChrome extends StatelessWidget {
  const ReaderChrome({
    required this.controller,
    required this.document,
    required this.bookmarked,
    required this.onBack,
    required this.onToggleBookmark,
    required this.onToolSelected,
    this.selectedTool = 0,
    super.key,
  });

  final ReaderController controller;
  final PdfDocument document;
  final bool bookmarked;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;
  final ValueChanged<int> onToolSelected;
  final int selectedTool;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final WaraqPalette palette = WaraqPalette.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final double safeBottom = media.padding.bottom;
    final double safeTop = media.padding.top;

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final bool visible = controller.chromeVisible;
        final bool scrubbing = controller.isScrubbing;
        final int indicatorPage = scrubbing
            ? (controller.scrubPage ?? controller.currentPage)
            : controller.currentPage;

        return Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, -0.45),
                  duration: Motion.base,
                  curve: Motion.emphasized,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: Motion.base,
                    curve: Motion.emphasized,
                    child: _TopBar(
                      document: document,
                      controller: controller,
                      bookmarked: bookmarked,
                      onBack: onBack,
                      onToggleBookmark: onToggleBookmark,
                      topInset: safeTop,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: Motion.base,
              curve: Motion.emphasized,
              left: 0,
              right: 0,
              bottom: safeBottom + (visible ? 108 : 22),
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: (visible || scrubbing || controller.indicatorVisible)
                      ? 1
                      : 0,
                  duration: Motion.fast,
                  child: Center(
                    child: _PagePill(
                      page: indicatorPage,
                      total: controller.pageCount,
                      palette: palette,
                      semanticsLabel:
                          strings.pageOf(indicatorPage, controller.pageCount),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: Gap.m,
              right: Gap.m,
              bottom: safeBottom + Gap.s,
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, 0.7),
                  duration: Motion.base,
                  curve: Motion.emphasized,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: Motion.base,
                    curve: Motion.emphasized,
                    child: _ToolDock(
                      controller: controller,
                      strings: strings,
                      palette: palette,
                      selectedTool: selectedTool,
                      onToolSelected: onToolSelected,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: safeBottom,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: visible ? 0 : 1,
                  duration: Motion.base,
                  child: _ImmersiveLine(
                    progress: controller.progress,
                    palette: palette,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.document,
    required this.controller,
    required this.bookmarked,
    required this.onBack,
    required this.onToggleBookmark,
    required this.topInset,
  });

  final PdfDocument document;
  final ReaderController controller;
  final bool bookmarked;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqPalette palette = WaraqPalette.of(context);
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: EdgeInsets.fromLTRB(Gap.m, topInset + Gap.s, Gap.m, 0),
      child: Container(
        height: 60,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: palette.chromeSurface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: palette.chromeBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.pageShadow.withFraction(0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  const SizedBox(width: Gap.xs),
                  IconButton(
                    onPressed: onBack,
                    tooltip: strings.back,
                    icon: Icon(
                      isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          strings.pageOf(
                            controller.currentPage,
                            controller.pageCount,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleBookmark,
                    tooltip: bookmarked
                        ? strings.removeBookmarkTooltip
                        : strings.bookmarkTooltip,
                    icon: PopIcon(
                      icon: bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      active: bookmarked,
                    ),
                  ),
                  const SizedBox(width: Gap.xs),
                ],
              ),
            ),
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: controller.progress.clamp(0.0, 1.0).toDouble(),
                minHeight: 2,
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PagePill extends StatelessWidget {
  const _PagePill({
    required this.page,
    required this.total,
    required this.palette,
    required this.semanticsLabel,
  });

  final int page;
  final int total;
  final WaraqPalette palette;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.s),
        decoration: BoxDecoration(
          color: palette.chromeSurface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: palette.chromeBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.pageShadow.withFraction(0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          '$page / $total',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _ToolDock extends StatelessWidget {
  const _ToolDock({
    required this.controller,
    required this.strings,
    required this.palette,
    required this.selectedTool,
    required this.onToolSelected,
  });

  final ReaderController controller;
  final AppStrings strings;
  final WaraqPalette palette;
  final int selectedTool;
  final ValueChanged<int> onToolSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.chromeSurface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: palette.chromeBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.pageShadow.withFraction(0.55),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6, left: Gap.s, right: Gap.s),
            child: PageScrubber(controller: controller),
          ),
          NavigationBar(
            selectedIndex: selectedTool.clamp(0, 3).toInt(),
            onDestinationSelected: onToolSelected,
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: const Icon(Icons.grid_view_rounded),
                label: strings.readerPages,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bookmark_border_rounded),
                label: strings.readerBookmarks,
              ),
              NavigationDestination(
                icon: Icon(
                  controller.isAutoScrolling
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                ),
                label: strings.readerAutoScroll,
              ),
              NavigationDestination(
                icon: const Icon(Icons.contrast_rounded),
                label: strings.readerDisplay,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImmersiveLine extends StatelessWidget {
  const _ImmersiveLine({required this.progress, required this.palette});

  final double progress;
  final WaraqPalette palette;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0).toDouble(),
      minHeight: 2,
      backgroundColor: palette.immersiveHairline.withFraction(0.25),
      color: scheme.primary.withFraction(0.85),
    );
  }
}
