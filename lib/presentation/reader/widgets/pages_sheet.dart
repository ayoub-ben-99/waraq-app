import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/waraq_sheet.dart';
import '../../../data/pdf/pdf_page_cache.dart';
import '../reader_controller.dart';
import 'pdf_page_view.dart';

/// Thumbnail grid plus "go to page": the fastest way to travel far inside a
/// long document.
class PagesSheet extends StatefulWidget {
  const PagesSheet({required this.controller, super.key});

  final ReaderController controller;

  @override
  State<PagesSheet> createState() => _PagesSheetState();
}

class _PagesSheetState extends State<PagesSheet> {
  late final PdfPageCache _thumbnails = PdfPageCache(
    renderer: widget.controller.renderer,
    maxEntries: 48,
    minRenderWidth: 120,
    maxRenderWidth: 260,
  );
  final TextEditingController _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final int target = page.clamp(1, math.max(1, widget.controller.pageCount)).toInt();
    widget.controller.jumpToPage(target);
    Navigator.of(context).pop();
  }

  void _submitField() {
    final int? page = int.tryParse(_field.text.trim());
    if (page != null) {
      _goTo(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ReaderController controller = widget.controller;

    return WaraqSheet(
      title: strings.pagesSheetTitle,
      subtitle: strings.pageOf(controller.currentPage, controller.pageCount),
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _field,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.go,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onSubmitted: (String _) => _submitField(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: strings.pageNumberHint,
                    prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                    filled: true,
                    fillColor: scheme.surfaceContainerHigh,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Gap.l,
                      vertical: Gap.m,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Gap.s),
              FilledButton(
                onPressed: _submitField,
                child: Text(strings.go),
              ),
            ],
          ),
          const SizedBox(height: Gap.l),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: Gap.s),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: Gap.m,
                crossAxisSpacing: Gap.m,
                childAspectRatio: 0.62,
              ),
              itemCount: controller.pageCount,
              itemBuilder: (BuildContext context, int index) {
                final bool isCurrent = index + 1 == controller.currentPage;
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    const double labelHeight = 20;
                    final double width = constraints.maxWidth;
                    final double height =
                        math.max(constraints.maxHeight - labelHeight, 24);
                    return InkWell(
                      onTap: () => _goTo(index + 1),
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            width: width,
                            height: height,
                            child: Stack(
                              children: <Widget>[
                                PdfPageView(
                                  cache: _thumbnails,
                                  pageIndex: index,
                                  width: width,
                                  height: height,
                                  pixelRatio: 1.4,
                                  radius: 6,
                                  filter: controller.filter,
                                ),
                                if (isCurrent)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: scheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${index + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isCurrent
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              fontWeight:
                                  isCurrent ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
