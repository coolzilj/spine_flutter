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

class SkeletonAnimation extends core.Skeleton {
  final core.AnimationState state;

  SkeletonAnimation(core.SkeletonData data)
      : state = new AnimationState(new core.AnimationStateData(data)),
        super(data);

  static Future<SkeletonAnimation> createWithFiles(
      String atlasDataFile, String skeltonDataFile, String textureDataFile,
      {String pathPrefix = ''}) async {
    if (atlasDataFile == null)
      throw new ArgumentError('atlasDataFile cannot be null.');
    if (skeltonDataFile == null)
      throw new ArgumentError('skeltonDataFile cannot be null.');
    if (textureDataFile == null)
      throw new ArgumentError('textureDataFile cannot be null.');
    if (pathPrefix == null)
      throw new ArgumentError('pathPrefix cannot be null.');

    final Map<String, dynamic> assets = await _loadAssets(
        atlasDataFile, skeltonDataFile, textureDataFile, pathPrefix);
    final core.TextureAtlas atlas = new core.TextureAtlas(
        assets[pathPrefix + atlasDataFile],
        (String path) => assets[pathPrefix + path]);
    final core.AtlasAttachmentLoader atlasLoader =
        new core.AtlasAttachmentLoader(atlas);
    final core.SkeletonJson skeletonJson = new core.SkeletonJson(atlasLoader);
    final core.SkeletonData skeletonData =
        skeletonJson.readSkeletonData(assets[pathPrefix + skeltonDataFile]);
    return new SkeletonAnimation(skeletonData);
  }

  static Future<Map<String, dynamic>> _loadAssets(String atlasDataFile,
      String skeltonDataFile, String textureDataFile, String pathPrefix) async {
    final Map<String, dynamic> loaded = <String, dynamic>{};
    final List<Future<MapEntry<String, dynamic>>> futures =
        <Future<MapEntry<String, dynamic>>>[
      new TextLoader()(pathPrefix + atlasDataFile),
      new TextureLoader()(pathPrefix + textureDataFile),
      new JsonLoader()(pathPrefix + skeltonDataFile)
    ];
    await Future.wait(futures).then(loaded.addEntries);
    return loaded;
  }
}
