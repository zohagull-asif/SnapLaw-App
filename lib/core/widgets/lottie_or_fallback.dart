import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget that tries to load a Lottie animation, falls back to provided widget if it fails
class LottieOrFallback extends StatelessWidget {
  final String animationPath;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool repeat;
  final bool animate;

  const LottieOrFallback({
    super.key,
    required this.animationPath,
    required this.fallback,
    this.width,
    this.height,
    this.fit,
    this.repeat = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkAssetExists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return Lottie.asset(
            animationPath,
            width: width,
            height: height,
            fit: fit ?? BoxFit.contain,
            repeat: repeat,
            animate: animate,
          );
        }

        return fallback;
      },
    );
  }

  Future<bool> _checkAssetExists() async {
    try {
      // Try to load the asset - if it fails, catch will return false
      await DefaultAssetBundle.of(
        // ignore: use_build_context_synchronously
        NavigatorState.maybeOf(
          // ignore: use_build_context_synchronously
          Navigator.of(
            // ignore: invalid_use_of_protected_member
            WidgetsBinding.instance.rootElement!,
          ).context,
        )?.context ??
            // ignore: invalid_use_of_protected_member
            WidgetsBinding.instance.rootElement!,
      ).load(animationPath);
      return true;
    } catch (e) {
      return false;
    }
  }
}
