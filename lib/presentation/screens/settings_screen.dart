import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/links.dart';
import '../../core/widgets/link_tile.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/section_header.dart';
import '../../data/data_providers.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/reader_settings.dart';
import '../providers/bookmark_providers.dart';
import '../providers/library_providers.dart';
import '../providers/settings_providers.dart';

/// Theme, reading defaults, storage and about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '4.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSettings settings = ref.watch(settingsProvider);
    final int librarySize = ref.watch(librarySizeProvider);

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double horizontal = math.max(
            Gap.xl,
            (constraints.maxWidth - Sizes.maxContentWidth) / 2,
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              Gap.m,
              horizontal,
              Gap.xxxl * 2,
            ),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: <Widget>[
              Text(strings.navSettings, style: theme.textTheme.displaySmall),
              const SizedBox(height: Gap.xs),
              Text(
                strings.appTagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SectionHeader(title: strings.sectionAppearance),
              _ThemeModeGrid(
                selected: settings.themeMode,
                onSelected: (AppThemeMode mode) => unawaited(
                  ref.read(settingsProvider.notifier).setThemeMode(mode),
                ),
              ),
              const SizedBox(height: Gap.m),
              _SettingsCard(
                children: <Widget>[
                  _SwitchRow(
                    icon: Icons.palette_outlined,
                    title: strings.dynamicColorTitle,
                    subtitle: strings.dynamicColorSubtitle,
                    value: settings.useDynamicColor,
                    onChanged: (bool value) => unawaited(
                      ref
                          .read(settingsProvider.notifier)
                          .setDynamicColor(enabled: value),
                    ),
                  ),
                  if (!settings.useDynamicColor) ...<Widget>[
                    const _CardDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Gap.l,
                        Gap.l,
                        Gap.l,
                        Gap.l,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            strings.accentTitle,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: Gap.m),
                          _AccentPicker(
                            selected: settings.accentSeed,
                            onSelected: (AccentSeed seed) => unawaited(
                              ref
                                  .read(settingsProvider.notifier)
                                  .setAccent(seed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              SectionHeader(title: strings.sectionShape),
              _SettingsCard(
                children: <Widget>[
                  _LabelRow(
                    icon: Icons.rounded_corner_rounded,
                    title: strings.shapeTitle,
                    subtitle: strings.shapeSubtitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                    child: _ShapePicker(
                      selected: settings.shapeStyle,
                      onSelected: (ShapeStyle style) => unawaited(
                        ref.read(settingsProvider.notifier).setShapeStyle(style),
                      ),
                    ),
                  ),
                  const _CardDivider(),
                  _Caption(text: strings.shapeHint),
                ],
              ),
              SectionHeader(title: strings.sectionMotion),
              _SettingsCard(
                children: <Widget>[
                  _LabelRow(
                    icon: Icons.animation_rounded,
                    title: strings.motionTitle,
                    subtitle: strings.motionSubtitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                    child: SegmentedButton<MotionStyle>(
                      showSelectedIcon: false,
                      segments: <ButtonSegment<MotionStyle>>[
                        ButtonSegment<MotionStyle>(
                          value: MotionStyle.full,
                          label: Text(strings.motionFull),
                        ),
                        ButtonSegment<MotionStyle>(
                          value: MotionStyle.reduced,
                          label: Text(strings.motionReduced),
                        ),
                        ButtonSegment<MotionStyle>(
                          value: MotionStyle.off,
                          label: Text(strings.motionOff),
                        ),
                      ],
                      selected: <MotionStyle>{settings.motionStyle},
                      onSelectionChanged: (Set<MotionStyle> selection) =>
                          unawaited(
                        ref
                            .read(settingsProvider.notifier)
                            .setMotionStyle(selection.first),
                      ),
                    ),
                  ),
                  const _CardDivider(),
                  _Caption(text: strings.motionHint),
                ],
              ),
              SectionHeader(title: strings.sectionReading),
              _SettingsCard(
                children: <Widget>[
                  _LabelRow(
                    icon: Icons.swap_vert_rounded,
                    title: strings.defaultScrollTitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                    child: SegmentedButton<ScrollMode>(
                      showSelectedIcon: false,
                      segments: <ButtonSegment<ScrollMode>>[
                        ButtonSegment<ScrollMode>(
                          value: ScrollMode.vertical,
                          icon: const Icon(Icons.swap_vert_rounded, size: 18),
                          label: Text(strings.scrollModeVertical),
                        ),
                        ButtonSegment<ScrollMode>(
                          value: ScrollMode.horizontal,
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: Text(strings.scrollModeHorizontal),
                        ),
                      ],
                      selected: <ScrollMode>{settings.reader.scrollMode},
                      onSelectionChanged: (Set<ScrollMode> selection) =>
                          unawaited(
                        ref.read(settingsProvider.notifier).updateReader(
                              (ReaderSettings reader) =>
                                  reader.copyWith(scrollMode: selection.first),
                            ),
                      ),
                    ),
                  ),
                  const _CardDivider(),
                  _LabelRow(
                    icon: Icons.contrast_rounded,
                    title: strings.defaultToneTitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                    child: Wrap(
                      spacing: Gap.s,
                      runSpacing: Gap.s,
                      children: <Widget>[
                        for (final PageFilter filter in PageFilter.values)
                          ChoiceChip(
                            label: Text(
                              switch (filter) {
                                PageFilter.none => strings.toneOriginal,
                                PageFilter.sepia => strings.toneSepia,
                                PageFilter.night => strings.toneNight,
                              },
                            ),
                            selected: settings.reader.pageFilter == filter,
                            onSelected: (bool _) => unawaited(
                              ref.read(settingsProvider.notifier).updateReader(
                                    (ReaderSettings reader) =>
                                        reader.copyWith(pageFilter: filter),
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.m),
              _SettingsCard(
                children: <Widget>[
                  _LabelRow(
                    icon: Icons.translate_rounded,
                    title: strings.languageTitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                    child: Wrap(
                      spacing: Gap.s,
                      runSpacing: Gap.s,
                      children: <Widget>[
                        for (final AppLanguage language in AppLanguage.values)
                          ChoiceChip(
                            label: Text(
                              switch (language) {
                                AppLanguage.system => strings.languageSystem,
                                AppLanguage.english => strings.languageEnglish,
                                AppLanguage.arabic => strings.languageArabic,
                              },
                            ),
                            selected: settings.language == language,
                            onSelected: (bool _) => unawaited(
                              ref
                                  .read(settingsProvider.notifier)
                                  .setLanguage(language),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SectionHeader(title: strings.sectionStorage),
              _SettingsCard(
                children: <Widget>[
                  _InfoRow(
                    icon: Icons.sd_storage_outlined,
                    title: strings.storageUsed,
                    value: formatBytes(librarySize),
                  ),
                  const _CardDivider(),
                  _ActionRow(
                    icon: Icons.cleaning_services_outlined,
                    title: strings.clearReadingData,
                    subtitle: strings.clearReadingDataBody,
                    onTap: () => unawaited(_clearReadingData(context, ref)),
                  ),
                ],
              ),
              SectionHeader(title: strings.sectionAbout),
              _SettingsCard(
                children: <Widget>[
                  _InfoRow(
                    icon: Icons.info_outline_rounded,
                    title: strings.versionLabel,
                    value: appVersion,
                  ),
                  const _CardDivider(),
                  Padding(
                    padding: const EdgeInsets.all(Gap.l),
                    child: Text(
                      strings.aboutBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              SectionHeader(title: strings.sectionCommunity),
              _SettingsCard(
                children: <Widget>[
                  LinkTile(
                    icon: Icons.chat_rounded,
                    title: strings.whatsappGroup,
                    subtitle: strings.whatsappGroupHint,
                    url: WaraqLinks.whatsapp,
                    accent: const Color(0xFF25D366),
                  ),
                  const _CardDivider(),
                  LinkTile(
                    icon: Icons.code_rounded,
                    title: strings.sourceCode,
                    subtitle: strings.sourceCodeHint,
                    url: WaraqLinks.github,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _clearReadingData(BuildContext context, WidgetRef ref) async {
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await ref.read(readingStateRepositoryProvider).clearAll();
    await ref.read(positionsProvider.notifier).refresh();
    ref.invalidate(bookmarksProvider);
    messenger.showSnackBar(
      SnackBar(content: Text(strings.readingDataCleared)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: scheme.outlineVariant.withFraction(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: Gap.l, endIndent: Gap.l);
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, Gap.m),
      child: Row(
        children: <Widget>[
          _IconBubble(icon: icon),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Gap.l),
      child: Row(
        children: <Widget>[
          _IconBubble(icon: icon),
          const SizedBox(width: Gap.m),
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Row(
          children: <Widget>[
            _IconBubble(icon: icon),
            const SizedBox(width: Gap.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withFraction(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.m, Gap.m),
      child: Row(
        children: <Widget>[
          _IconBubble(icon: icon),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Icon(icon, size: 19, color: scheme.onSurfaceVariant),
    );
  }
}

class _ThemeModeGrid extends StatelessWidget {
  const _ThemeModeGrid({required this.selected, required this.onSelected});

  final AppThemeMode selected;
  final ValueChanged<AppThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tileWidth = (constraints.maxWidth - Gap.s) / 2;
        return Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: <Widget>[
            for (final AppThemeMode mode in AppThemeMode.values)
              SizedBox(
                width: tileWidth,
                child: _ThemeTile(
                  mode: mode,
                  selected: selected == mode,
                  onTap: () => onSelected(mode),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final IconData icon = switch (mode) {
      AppThemeMode.system => Icons.brightness_auto_rounded,
      AppThemeMode.light => Icons.light_mode_rounded,
      AppThemeMode.dark => Icons.dark_mode_rounded,
      AppThemeMode.amoled => Icons.contrast_rounded,
    };
    final String label = switch (mode) {
      AppThemeMode.system => strings.themeSystem,
      AppThemeMode.light => strings.themeLight,
      AppThemeMode.dark => strings.themeDark,
      AppThemeMode.amoled => strings.themeAmoled,
    };
    final String? hint = switch (mode) {
      AppThemeMode.system => strings.themeSystemHint,
      AppThemeMode.amoled => strings.themeAmoledHint,
      _ => null,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.emphasized,
        padding: const EdgeInsets.all(Gap.m),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 20,
              color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: Gap.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0,
                        fontWeight: FontWeight.w400,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: Motion.fast,
              child: Icon(Icons.check_rounded, size: 16, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.selected, required this.onSelected});

  final AccentSeed selected;
  final ValueChanged<AccentSeed> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: Gap.m,
      runSpacing: Gap.m,
      children: <Widget>[
        for (final AccentSeed seed in AccentSeed.values)
          GestureDetector(
            onTap: () => onSelected(seed),
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.emphasized,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: seedColorOf(seed),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == seed ? scheme.onSurface : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: seedColorOf(seed).withFraction(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: selected == seed
                  ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Three corner previews, so the choice is visible instead of described.
class _ShapePicker extends StatelessWidget {
  const _ShapePicker({required this.selected, required this.onSelected});

  final ShapeStyle selected;
  final ValueChanged<ShapeStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final ShapeStyle style in ShapeStyle.values) ...<Widget>[
          Expanded(
            child: _ShapeOption(
              style: style,
              selected: selected == style,
              onTap: () => onSelected(style),
            ),
          ),
          if (style != ShapeStyle.values.last) const SizedBox(width: Gap.s),
        ],
      ],
    );
  }
}

class _ShapeOption extends StatelessWidget {
  const _ShapeOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final ShapeStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape preview = WaraqShape.forStyle(style);

    final String label = switch (style) {
      ShapeStyle.soft => strings.shapeSoft,
      ShapeStyle.rounded => strings.shapeRounded,
      ShapeStyle.square => strings.shapeSquare,
    };

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: preview.allMd,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.emphasized,
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.s,
            vertical: Gap.m,
          ),
          decoration: BoxDecoration(
            color: selected
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: preview.allMd,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.onSecondaryContainer.withFraction(0.16)
                      : scheme.onSurfaceVariant.withFraction(0.14),
                  borderRadius: BorderRadius.circular(preview.md),
                ),
              ),
              const SizedBox(height: Gap.s),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muted explanatory line under a setting.
class _Caption extends StatelessWidget {
  const _Caption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, Gap.m),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}
