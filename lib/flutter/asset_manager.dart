/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of spine_flutter;

class Assets {
  final String skeltonDataFile;
  final String atlasDataFile;
  final String textureDataFile;
  final String pathPrefix;

  const Assets({
    @required this.skeltonDataFile,
    @required this.atlasDataFile,
    @required this.textureDataFile,
    this.pathPrefix = '',
  });
}

class AssetDescriptor<T> {
  final String name;
  final AssetLoader<T> loader;

  const AssetDescriptor(this.name, this.loader);
}

class AssetManager implements core.Disposable {
  final List<AssetDescriptor<dynamic>> _loadQueue =
      <AssetDescriptor<dynamic>>[];
  final Map<String, dynamic> _assets = <String, dynamic>{};

  String _pathPrefix;

  void add<T>(String name, AssetLoader<T> loader) {
    _loadQueue.add(new AssetDescriptor<T>(name, loader));
  }

  @override
  void dispose() {
    removeAll();
  }

  Future<bool> load() async {
    final List<Future<MapEntry<String, dynamic>>> futures =
        <Future<MapEntry<String, dynamic>>>[];

    _loadQueue.forEach((AssetDescriptor<dynamic> descriptor) {
      futures.add(descriptor.loader(_pathPrefix + descriptor.name));
    });

    bool success = true;

    await Future.wait(futures).then((List<MapEntry<String, dynamic>> assets) {
      _assets.addEntries(assets);
      _loadQueue.clear();
    }).catchError((Error e) {
      success = false;
    });

    return success;
  }

  dynamic get(String name) => _assets[_pathPrefix + name];

  String get pathPrefix => _pathPrefix;
  set pathPrefix(String value) {
    if (_pathPrefix == value) {
      return;
    }
    _pathPrefix = value;
    removeAll();
  }

  bool isLoadingComplete() => _loadQueue.isEmpty;

  void removeAll() {
    for (String key in _assets.keys) {
      final dynamic asset = _assets[key];
      if (asset is core.Disposable) asset.dispose();
    }
    _assets.clear();
  }
}
