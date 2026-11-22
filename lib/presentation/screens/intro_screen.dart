import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';

/// First paint of every launch: the mark springs in, the name rises, and the
/// shell takes over on its own after about two seconds.
class IntroScreen extends StatefulWidget {
  const IntroScreen({required this.onDone, super.key});

  final VoidCallback onDone;

  /// Long enough to read the name, short enough not to be in the way.
  static const Duration hold = Duration(milliseconds: 1900);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  Timer? _timer;
  bool _started = false;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _reduced = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        !WaraqMotion.of(context).enabled;
    if (_reduced) {
      _controller.value = 1;
    } else {
      unawaited(_controller.forward());
    }
    _timer = Timer(
      _reduced ? const Duration(milliseconds: 900) : IntroScreen.hold,
      widget.onDone,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Animation<double> mark = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.65, curve: Curves.easeOutBack),
    );
    final Animation<double> markFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    final Animation<double> name = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic),
    );
    final Animation<double> tagline = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FadeTransition(
              opacity: markFade,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.72, end: 1).animate(mark),
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icon.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Gap.xl),
            _Rise(
              animation: name,
              child: Text(
                strings.appName,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: Gap.s),
            _Rise(
              animation: tagline,
              child: Text(
                strings.appTagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slide-up plus fade, driven by one animation.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return Transform.translate(
            offset: Offset(0, 18 * (1 - animation.value)),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}
