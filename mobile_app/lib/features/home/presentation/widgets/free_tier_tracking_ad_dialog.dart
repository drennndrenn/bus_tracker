import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/tracking_ad_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../subscription/presentation/pages/plans_page.dart';

/// Full-screen ad gate for free commuters before tracking starts.
class FreeTierTrackingAdDialog extends StatefulWidget {
  const FreeTierTrackingAdDialog({super.key});

  /// Returns `true` if the user completed the ad and tracking may start.
  static Future<bool> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (ctx) => const FreeTierTrackingAdDialog(),
    ).then((value) => value == true);
  }

  @override
  State<FreeTierTrackingAdDialog> createState() => _FreeTierTrackingAdDialogState();
}

class _FreeTierTrackingAdDialogState extends State<FreeTierTrackingAdDialog> {
  static const _countdownTotal = TrackingAdConstants.countdownSeconds;

  VideoPlayerController? _videoController;
  Timer? _countdownTimer;
  bool _videoLoading = true;
  bool _canContinue = false;
  bool _isVideoAd = false;
  bool _adClosed = false;
  bool _isMuted = false;
  int _secondsLeft = _countdownTotal;
  int _videoSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _initVideoAd();
  }

  Future<void> _initVideoAd() async {
    final controller = VideoPlayerController.asset(TrackingAdConstants.adVideoAsset);
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(_isMuted ? 0.0 : 1.0);
      controller.addListener(_onVideoUpdate);
      await controller.play();

      if (!mounted) {
        controller.removeListener(_onVideoUpdate);
        await controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _isVideoAd = true;
        _videoLoading = false;
        _videoSecondsLeft = controller.value.duration.inSeconds.clamp(1, 999);
      });
      _startCountdown();
    } catch (_) {
      controller.removeListener(_onVideoUpdate);
      await controller.dispose();
      if (!mounted) return;
      _startImageFallback();
    }
  }

  void _startImageFallback() {
    setState(() {
      _videoLoading = false;
      _isVideoAd = false;
      _secondsLeft = _countdownTotal;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _adClosed) return;
      if (_secondsLeft <= 1) {
        _countdownTimer?.cancel();
        setState(() {
          _secondsLeft = 0;
          _canContinue = true;
        });
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  void _onVideoUpdate() {
    if (!mounted || _adClosed) return;
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    final value = controller.value;
    final duration = value.duration;
    final position = value.position;

    if (value.isCompleted ||
        (duration.inMilliseconds > 0 && position >= duration)) {
      _finishAd();
      return;
    }

    final durationSeconds = duration.inSeconds.clamp(1, 999);
    final remaining = (duration - position).inSeconds.clamp(0, durationSeconds);
    if (_videoSecondsLeft != remaining) {
      setState(() => _videoSecondsLeft = remaining);
    }
  }

  void _finishAd() {
    if (_adClosed || !mounted) return;
    _adClosed = true;
    _countdownTimer?.cancel();
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    super.dispose();
  }

  void _openPlans() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PlansPage()),
    );
  }

  Future<void> _toggleMute() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    final nextMuted = !_isMuted;
    await controller.setVolume(nextMuted ? 0.0 : 1.0);
    if (!mounted) return;
    setState(() => _isMuted = nextMuted);
  }

  double get _countdownProgress =>
      (1 - _secondsLeft / _countdownTotal).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isVideoAd ? 'Sponsored video' : 'Sponsored',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_canContinue)
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _finishAd,
                      icon: const Icon(Icons.close, color: AppColors.gray600),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _buildAdMedia(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isVideoAd
                    ? (_canContinue
                        ? 'Tap Continue anytime, or tracking starts when the ad ends.'
                        : 'Short sponsored clip — Pro members skip ads and track instantly.')
                    : 'Thanks for supporting free bus tracking in Davao del Norte.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              if (_videoLoading)
                const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.blue600),
                  ),
                )
              else if (!_canContinue) ...[
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _countdownProgress,
                        strokeWidth: 4,
                        color: AppColors.blue600,
                        backgroundColor: AppColors.blue100,
                      ),
                      Text(
                        '$_secondsLeft',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.blue600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue in $_secondsLeft sec…',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _finishAd,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue to tracking',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
                if (_isVideoAd && _videoSecondsLeft > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ad playing · $_videoSecondsLeft sec left',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _openPlans,
                icon: const Icon(Icons.workspace_premium_outlined, size: 20),
                label: const Text(
                  'Go Pro — ad-free tracking',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdMedia() {
    if (_videoLoading) {
      return Container(
        color: AppColors.gray900,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final controller = _videoController;
    if (_isVideoAd && controller != null && controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _VideoMuteButton(
              isMuted: _isMuted,
              onPressed: () => _toggleMute(),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Ad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return const _AdImage();
  }
}

class _VideoMuteButton extends StatelessWidget {
  const _VideoMuteButton({
    required this.isMuted,
    required this.onPressed,
  });

  final bool isMuted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        tooltip: isMuted ? 'Unmute ad' : 'Mute ad',
        icon: Icon(
          isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: Colors.white,
          size: 22,
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}

class _AdImage extends StatelessWidget {
  const _AdImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      TrackingAdConstants.adImageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          TrackingAdConstants.fallbackImageAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.blue50,
            child: const Center(
              child: Icon(Icons.campaign_rounded, size: 64, color: AppColors.blue600),
            ),
          ),
        );
      },
    );
  }
}
