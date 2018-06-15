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

class SkeletonRenderObjectWidget extends LeafRenderObjectWidget {
  final Assets assets;
  final String skinName;
  final AnimationSettings animationSettings;
  final BoxFit fit;
  final Alignment alignment;
  final PlayState playState;
  final core.TrackEntryCallback onStartCallback;
  final core.TrackEntryCallback onInterruptCallback;
  final core.TrackEntryCallback onEndCallback;
  final core.TrackEntryCallback onDisposeCallback;
  final core.TrackEntryCallback onCompleteCallback;
  final core.TrackEntryEventCallback onEventCallback;

  const SkeletonRenderObjectWidget(
      {this.assets,
      this.skinName,
      this.animationSettings,
      this.fit,
      this.alignment = Alignment.center,
      this.playState = PlayState.Playing,
      this.onStartCallback,
      this.onInterruptCallback,
      this.onEndCallback,
      this.onDisposeCallback,
      this.onCompleteCallback,
      this.onEventCallback});

  @override
  RenderObject createRenderObject(BuildContext context) {
    debugPrint("called: createRenderObject");
    return new SkeletonRenderObject()
      ..assets = assets
      ..fit = fit
      ..alignment = alignment
      ..skinName = skinName
      ..animationSettings = animationSettings
      ..playState =
          (playState == PlayState.Playing && animationSettings != null)
              ? PlayState.Playing
              : PlayState.Paused;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant SkeletonRenderObject renderObject) {
    renderObject
      ..assets = assets
      ..fit = fit
      ..alignment = alignment
      ..skinName = skinName
      ..animationSettings = animationSettings
      ..playState =
          (playState == PlayState.Playing && animationSettings != null)
              ? PlayState.Playing
              : PlayState.Paused;
  }
}

class SkeletonRenderObject extends RenderBox {
  final AssetManager assetManager;
  Assets _assets;
  String _skinName;
  AnimationSettings _animationSettings;
  BoxFit _fit;
  Alignment _alignment;
  PlayState _playState;
  double _lastFrameTime = 0.0;
  core.TrackEntryCallback _onStartCallback;
  core.TrackEntryCallback _onInterruptCallback;
  core.TrackEntryCallback _onEndCallback;
  core.TrackEntryCallback _onDisposeCallback;
  core.TrackEntryCallback _onCompleteCallback;
  core.TrackEntryEventCallback _onEventCallback;

  SkeletonRenderer _skeletonRenderer;
  core.Skeleton _skeleton;
  AnimationState _animationState;
  core.Bounds _bounds;

  SkeletonRenderObject() : assetManager = new AssetManager();

  void load() {
    if (_assets == null) {
      return;
    }

    assetManager.load().then((bool success) {
      final atlasText = assetManager.get(_assets.atlasDataFile);
      final textureLoader = assetManager.get;
      final core.TextureAtlas atlas =
          core.TextureAtlas(atlasText, textureLoader);
      final core.AtlasAttachmentLoader atlasLoader =
          core.AtlasAttachmentLoader(atlas);
      final core.SkeletonJson skeletonJson = core.SkeletonJson(atlasLoader);
      final core.SkeletonData skeletonData = skeletonJson
          .readSkeletonData(assetManager.get(_assets.skeltonDataFile));
      final core.Skeleton skeleton = core.Skeleton(skeletonData);
      final core.Bounds bounds = _calculateBounds(skeleton);
      skeleton.setSkinByName(_skinName ?? 'default');
      final AnimationState animationState =
          AnimationState(new core.AnimationStateData(skeleton.data))
            ..setAnimationSettings(_animationSettings);
      if (_onStartCallback != null)
        animationState.addOnStartCallback(_onStartCallback);
      if (_onInterruptCallback != null)
        animationState.addOnInterruptCallback(_onInterruptCallback);
      if (_onEndCallback != null)
        animationState.addOnEndCallback(_onEndCallback);
      if (_onDisposeCallback != null)
        animationState.addOnDisposeCallback(_onDisposeCallback);
      if (_onCompleteCallback != null)
        animationState.addOnCompleteCallback(_onCompleteCallback);
      if (_onEventCallback != null)
        animationState.addOnEventCallback(_onEventCallback);
      _skeleton = skeleton;
      _animationState = animationState;
      _bounds = bounds;

      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    });
  }

  void beginFrame(Duration timeStamp) {
    final double t =
        timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;

    if (_lastFrameTime == 0 || _skeleton == null) {
      _lastFrameTime = t;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      return;
    }

    final double deltaTime = t - _lastFrameTime;
    _lastFrameTime = t;

    _animationState
      ..update(deltaTime)
      ..apply(_skeleton);
    _skeleton.updateWorldTransform();

    if (_playState == PlayState.Playing) {
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }

    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    if (_skeleton == null) {
      return;
    }

    final Canvas canvas = context.canvas;
    _skeletonRenderer ??= new SkeletonRenderer()
      // enable debug rendering
      ..debugRendering = true
      // enable the triangle renderer, supports meshes, but may produce artifacts in some browsers
      ..triangleRendering = true;

    resize(canvas, offset);

    _skeletonRenderer
      ..canvas = canvas
      ..draw(_skeleton);
    canvas.restore();
  }

  void resize(Canvas canvas, ui.Offset offset) {
    canvas
      ..save()
      ..clipRect(offset & size);

    final double contentHeight = _bounds.size.y;
    final double contentWidth = _bounds.size.x;
    final double x = -_bounds.offset.x -
        contentWidth / 2.0 -
        (_alignment.x * contentWidth / 2.0);
    final double y = -_bounds.offset.y -
        contentHeight / 2.0 +
        (_alignment.y * contentHeight / 2.0);
    double scaleX = 1.0, scaleY = 1.0;

    switch (_fit) {
      case BoxFit.fill:
        scaleX = size.width / contentWidth;
        scaleY = size.height / contentHeight;
        break;
      case BoxFit.contain:
        final double minScale =
            math.min(size.width / contentWidth, size.height / contentHeight);
        scaleX = scaleY = minScale;
        break;
      case BoxFit.cover:
        final double maxScale =
            math.max(size.width / contentWidth, size.height / contentHeight);
        scaleX = scaleY = maxScale;
        break;
      case BoxFit.fitHeight:
        final double minScale = size.height / contentHeight;
        scaleX = scaleY = minScale;
        break;
      case BoxFit.fitWidth:
        final double minScale = size.width / contentWidth;
        scaleX = scaleY = minScale;
        break;
      case BoxFit.none:
        scaleX = scaleY = 1.0;
        break;
      case BoxFit.scaleDown:
        final double minScale =
            math.min(size.width / contentWidth, size.height / contentHeight);
        scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
        break;
    }

    canvas
      ..translate(
          offset.dx + size.width / 2.0 + (_alignment.x * size.width / 2.0),
          offset.dy + size.height / 2.0 + (_alignment.y * size.height / 2.0))
      ..scale(scaleX, -scaleY)
      ..translate(x, y);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool hitTestSelf(Offset screenOffset) => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  Assets get assets => _assets;
  set assets(Assets value) {
    if (value == _assets) {
      return;
    }
    _assets = value;
    assetManager
      ..add(_assets.skeltonDataFile, JsonLoader())
      ..add(_assets.textureDataFile, TextureLoader())
      ..add(_assets.atlasDataFile, TextLoader());
    assetManager.pathPrefix = _assets.pathPrefix;
    load();
  }

  String get skinName => _skinName;
  set skinName(String value) {
    if (value == _skinName) {
      return;
    }
    _skinName = value;
    markNeedsPaint();
  }

  AnimationSettings get animationSettings => _animationSettings;
  set animationSettings(AnimationSettings value) {
    if (value == null) {
      return;
    }
    _animationSettings = value;
    _updateAnimation();
  }

  AlignmentGeometry get alignment => _alignment;
  set alignment(AlignmentGeometry value) {
    if (value == _alignment) {
      return;
    }
    _alignment = value;
    markNeedsPaint();
  }

  BoxFit get fit => _fit;
  set fit(BoxFit value) {
    if (value == _fit) {
      return;
    }
    _fit = value;
    markNeedsPaint();
  }

  PlayState get playState => _playState;
  set playState(PlayState value) {
    if (value == _playState) {
      return;
    }

    _playState = value;

    if (_playState == PlayState.Playing) {
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }

  core.TrackEntryCallback get onStartCallback => _onStartCallback;
  set onStartCallback(core.TrackEntryCallback value) {
    if (_onStartCallback == value) {
      return;
    }
    _onStartCallback = value;
  }

  core.TrackEntryCallback get onInterruptCallback => _onInterruptCallback;
  set onInterruptCallback(core.TrackEntryCallback value) {
    if (_onInterruptCallback == value) {
      return;
    }
    _onInterruptCallback = value;
  }

  core.TrackEntryCallback get onEndCallback => _onEndCallback;
  set onEndCallback(core.TrackEntryCallback value) {
    if (_onEndCallback == value) {
      return;
    }
    _onEndCallback = value;
  }

  core.TrackEntryCallback get onDisposeCallback => _onDisposeCallback;
  set onDisposeCallback(core.TrackEntryCallback value) {
    if (_onStartCallback == value) {
      return;
    }
    _onStartCallback = value;
  }

  core.TrackEntryCallback get onCompleteCallback => _onCompleteCallback;
  set onCompleteCallback(core.TrackEntryCallback value) {
    if (_onCompleteCallback == value) {
      return;
    }
    _onCompleteCallback = value;
  }

  core.TrackEntryEventCallback get onEventCallback => _onEventCallback;
  set onEventCallback(core.TrackEntryEventCallback value) {
    if (_onEventCallback == value) {
      return;
    }
    _onEventCallback = value;
  }

  core.Bounds _calculateBounds(core.Skeleton skeleton) {
    skeleton
      ..setToSetupPose()
      ..updateWorldTransform();
    final core.Vector2 offset = new core.Vector2();
    final core.Vector2 size = new core.Vector2();
    skeleton.getBounds(offset, size, <double>[]);

    return new core.Bounds(offset, size);

//     var data = skeleton.data;
//     skeleton.setToSetupPose();
//     skeleton.updateWorldTransform();
//     var offset = new spine.Vector2();
//     var size = new spine.Vector2();
//     skeleton.getBounds(offset, size, []);
//     return { offset: offset, size: size };
  }

  void _updateAnimation() {
    if (_animationSettings == null || _skeleton == null) {
      return;
    }
    _animationState.setAnimationSettings(_animationSettings);
    markNeedsPaint();
  }
}
