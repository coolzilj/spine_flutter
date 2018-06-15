// ******************************************************************************
// Spine Runtimes Software License v2.5
//
// Copyright (c) 2013-2016, Esoteric Software
// All rights reserved.
//
// You are granted a perpetual, non-exclusive, non-sublicensable, and
// non-transferable license to use, install, execute, and perform the Spine
// Runtimes software and derivative works solely for personal or internal
// use. Without the written permission of Esoteric Software (see Section 2 of
// the Spine Software License Agreement), you may not (a) modify, translate,
// adapt, or develop new applications using the Spine Runtimes or otherwise
// create derivative works or improvements of the Spine Runtimes or (b) remove,
// delete, alter, or obscure any trademarks or any copyright, trademark, patent,
// or other intellectual property or proprietary rights notices on or in the
// Software, including any copy thereof. Redistributions in binary or source
// form must include this license and terms.
//
// THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
// EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
// USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
// IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// ******************************************************************************

part of spine_flutter;

class AnimationState extends core.AnimationState {
  AnimationState(core.AnimationStateData data) : super(data);

  List<core.TrackEntry> setAnimationSettings(
      AnimationSettings animationSettings) {
    if (animationSettings == null)
      throw new ArgumentError('animation settings cannot be null.');
    final List<core.TrackEntry> trackEntries = <core.TrackEntry>[]..add(
        setAnimation(animationSettings.trackIndex,
            animationSettings.animationName, animationSettings.loop));
    animationSettings._additionals.forEach((AnimationSettings settings) {
      trackEntries.add(addAnimation(settings.trackIndex, settings.animationName,
          settings.loop, settings.delay));
    });
    return trackEntries;
  }
}

class AnimationSettings {
  final int trackIndex;
  final String animationName;
  final bool loop;
  final double delay;
  final List<AnimationSettings> _additionals = <AnimationSettings>[];
  AnimationSettings(this.trackIndex, this.animationName, this.loop)
      : delay = 0.0;
  AnimationSettings._additional(
      this.trackIndex, this.animationName, this.loop, this.delay);

  void addAdditional(
          int trackIndex, String animationName, bool loop, double delay) =>
      _additionals.add(new AnimationSettings._additional(
          trackIndex, animationName, loop, delay));
  void removeAdditional(
      int trackIndex, String animationName, bool loop, double delay) {
    int index = -1;
    final int n = _additionals.length;
    for (int i = 0; i < n; i++) {
      if (_additionals[i].trackIndex == trackIndex &&
          _additionals[i].animationName == animationName &&
          _additionals[i].loop == loop &&
          _additionals[i].delay == delay) {
        index = i;
        break;
      }
    }
    if (index >= 0) _additionals.removeAt(index);
  }

  void clearAdditionals() => _additionals.length = 0;

  int getAdditionalCount() => _additionals.length;
}

enum PlayState { Paused, Playing }
