// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

class SkwasmRenderer implements Renderer {
  late SkwasmSurface surface;
  final Map<EngineFlutterView, EngineSceneView> _sceneViews =
      <EngineFlutterView, EngineSceneView>{};

  bool get isMultiThreaded => skwasmIsMultiThreaded();

  SkwasmPathConstructors pathConstructors = SkwasmPathConstructors();

  @override
  final SkwasmFontCollection fontCollection = SkwasmFontCollection();

  @override
  ui.Path combinePaths(ui.PathOperation op, ui.Path path1, ui.Path path2) {
    return LazyPath.combined(op, path1 as LazyPath, path2 as LazyPath);
  }

  @override
  ui.Path copyPath(ui.Path src) {
    return LazyPath.fromLazyPath(src as LazyPath);
  }

  @override
  ui.Canvas createCanvas(ui.PictureRecorder recorder, [ui.Rect? cullRect]) {
    return SkwasmCanvas(recorder as SkwasmPictureRecorder, cullRect ?? ui.Rect.largest);
  }

  @override
  ui.Gradient createConicalGradient(
    ui.Offset focal,
    double focalRadius,
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix,
  ]) => SkwasmGradient.conical(
    focal: focal,
    focalRadius: focalRadius,
    center: center,
    centerRadius: radius,
    colors: colors,
    colorStops: colorStops,
    tileMode: tileMode,
    matrix4: matrix,
  );

  @override
  ui.ImageFilter createBlurImageFilter({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode? tileMode,
  }) => SkwasmImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY, tileMode: tileMode);

  @override
  ui.ImageFilter createDilateImageFilter({double radiusX = 0.0, double radiusY = 0.0}) =>
      SkwasmImageFilter.dilate(radiusX: radiusX, radiusY: radiusY);

  @override
  ui.ImageFilter createErodeImageFilter({double radiusX = 0.0, double radiusY = 0.0}) =>
      SkwasmImageFilter.erode(radiusX: radiusX, radiusY: radiusY);

  @override
  ui.ImageFilter composeImageFilters({
    required ui.ImageFilter outer,
    required ui.ImageFilter inner,
  }) => SkwasmImageFilter.compose(
    SkwasmImageFilter.fromUiFilter(outer),
    SkwasmImageFilter.fromUiFilter(inner),
  );

  @override
  ui.ImageFilter createMatrixImageFilter(
    Float64List matrix4, {
    ui.FilterQuality filterQuality = ui.FilterQuality.low,
  }) => SkwasmImageFilter.matrix(matrix4, filterQuality: filterQuality);

  @override
  ui.ImageShader createImageShader(
    ui.Image image,
    ui.TileMode tmx,
    ui.TileMode tmy,
    Float64List matrix4,
    ui.FilterQuality? filterQuality,
  ) => SkwasmImageShader.imageShader(image as SkwasmImage, tmx, tmy, matrix4, filterQuality);

  @override
  ui.Gradient createLinearGradient(
    ui.Offset from,
    ui.Offset to,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  ]) => SkwasmGradient.linear(
    from: from,
    to: to,
    colors: colors,
    colorStops: colorStops,
    tileMode: tileMode,
    matrix4: matrix4,
  );

  @override
  ui.Paint createPaint() => SkwasmPaint();

  @override
  ui.ParagraphBuilder createParagraphBuilder(ui.ParagraphStyle style) =>
      SkwasmParagraphBuilder(style as SkwasmParagraphStyle, fontCollection);

  @override
  ui.ParagraphStyle createParagraphStyle({
    ui.TextAlign? textAlign,
    ui.TextDirection? textDirection,
    int? maxLines,
    String? fontFamily,
    double? fontSize,
    double? height,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.StrutStyle? strutStyle,
    String? ellipsis,
    ui.Locale? locale,
  }) => SkwasmParagraphStyle(
    textAlign: textAlign,
    textDirection: textDirection,
    maxLines: maxLines,
    fontFamily: fontFamily,
    fontSize: fontSize,
    height: height,
    textHeightBehavior: textHeightBehavior,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    strutStyle: strutStyle,
    ellipsis: ellipsis,
    locale: locale,
  );

  @override
  ui.Path createPath() => LazyPath(pathConstructors);

  @override
  ui.PictureRecorder createPictureRecorder() => SkwasmPictureRecorder();

  @override
  ui.Gradient createRadialGradient(
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  ]) => SkwasmGradient.radial(
    center: center,
    radius: radius,
    colors: colors,
    colorStops: colorStops,
    tileMode: tileMode,
    matrix4: matrix4,
  );

  @override
  ui.SceneBuilder createSceneBuilder() => EngineSceneBuilder();

  @override
  ui.StrutStyle createStrutStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    double? leading,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    bool? forceStrutHeight,
  }) => SkwasmStrutStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize,
    height: height,
    leadingDistribution: leadingDistribution,
    leading: leading,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    forceStrutHeight: forceStrutHeight,
  );

  @override
  ui.Gradient createSweepGradient(
    ui.Offset center,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    double startAngle = 0.0,
    double endAngle = math.pi * 2,
    Float32List? matrix4,
  ]) => SkwasmGradient.sweep(
    center: center,
    colors: colors,
    colorStops: colorStops,
    tileMode: tileMode,
    startAngle: startAngle,
    endAngle: endAngle,
    matrix4: matrix4,
  );

  @override
  ui.TextStyle createTextStyle({
    ui.Color? color,
    ui.TextDecoration? decoration,
    ui.Color? decorationColor,
    ui.TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.TextBaseline? textBaseline,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    ui.Locale? locale,
    ui.Paint? background,
    ui.Paint? foreground,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
  }) => SkwasmTextStyle(
    color: color,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    textBaseline: textBaseline,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
    height: height,
    leadingDistribution: leadingDistribution,
    locale: locale,
    background: background,
    foreground: foreground,
    shadows: shadows,
    fontFeatures: fontFeatures,
    fontVariations: fontVariations,
  );

  @override
  ui.Vertices createVertices(
    ui.VertexMode mode,
    List<ui.Offset> positions, {
    List<ui.Offset>? textureCoordinates,
    List<ui.Color>? colors,
    List<int>? indices,
  }) => SkwasmVertices(
    mode,
    positions,
    textureCoordinates: textureCoordinates,
    colors: colors,
    indices: indices,
  );

  @override
  ui.Vertices createVerticesRaw(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  }) => SkwasmVertices.raw(
    mode,
    positions,
    textureCoordinates: textureCoordinates,
    colors: colors,
    indices: indices,
  );

  @override
  void decodeImageFromPixels(
    Uint8List pixels,
    int width,
    int height,
    ui.PixelFormat format,
    ui.ImageDecoderCallback callback, {
    int? rowBytes,
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
  }) {
    final SkwasmImage pixelImage = SkwasmImage.fromPixels(pixels, width, height, format);
    final ui.Image scaledImage = scaleImageIfNeeded(
      pixelImage,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: allowUpscaling,
    );
    callback(scaledImage);
  }

  @override
  FutureOr<void> initialize() {
    surface = SkwasmSurface();
  }

  @override
  Future<ui.Codec> instantiateImageCodec(
    Uint8List list, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
  }) async {
    final ImageType? contentType = detectImageType(list);
    if (contentType == null) {
      throw Exception('Could not determine content type of image from data');
    }
    if (browserSupportsImageDecoder) {
      final SkwasmBrowserImageDecoder baseDecoder = SkwasmBrowserImageDecoder(
        contentType: contentType.mimeType,
        dataSource: list.toJS,
        debugSource: 'encoded image bytes',
      );
      await baseDecoder.initialize();
      if (targetWidth == null && targetHeight == null) {
        return baseDecoder;
      }
      return ResizingCodec(
        baseDecoder,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: allowUpscaling,
      );
    } else {
      if (contentType.isAnimated) {
        return SkwasmAnimatedImageDecoder(list, targetWidth, targetHeight);
      } else {
        final DomBlob blob = createDomBlob(<ByteBuffer>[list.buffer]);
        return SkwasmDomImageDecoder(blob, targetWidth, targetHeight);
      }
    }
  }

  @override
  Future<ui.Codec> instantiateImageCodecFromUrl(
    Uri uri, {
    ui_web.ImageCodecChunkCallback? chunkCallback,
  }) async {
    final DomResponse response = await rawHttpGet(uri.toString());
    final String? contentType = response.headers.get('Content-Type');
    if (contentType == null) {
      throw Exception('Could not determine content type of image at url $uri');
    }
    if (browserSupportsImageDecoder) {
      final SkwasmBrowserImageDecoder decoder = SkwasmBrowserImageDecoder(
        contentType: contentType,
        dataSource: response.body,
        debugSource: uri.toString(),
      );
      await decoder.initialize();
      return decoder;
    } else {
      final ByteBuffer buffer = await response.arrayBuffer();
      final Uint8List data = buffer.asUint8List();
      final ImageType? parsedContentType = detectImageType(data);
      if (parsedContentType == null) {
        throw Exception('Could not determine content type of image from data');
      }
      if (parsedContentType.isAnimated) {
        return SkwasmAnimatedImageDecoder(data);
      } else {
        final DomBlob blob = createDomBlob(<ByteBuffer>[buffer]);
        return SkwasmDomImageDecoder(blob);
      }
    }
  }

  @override
  Future<void> renderScene(ui.Scene scene, EngineFlutterView view) {
    final FrameTimingRecorder? recorder = FrameTimingRecorder.frameTimingsEnabled
        ? FrameTimingRecorder()
        : null;
    recorder?.recordBuildFinish();

    final EngineSceneView sceneView = _getSceneViewForView(view);
    return sceneView.renderScene(scene as EngineScene, recorder);
  }

  EngineSceneView _getSceneViewForView(EngineFlutterView view) {
    return _sceneViews.putIfAbsent(view, () {
      final EngineSceneView sceneView = EngineSceneView(SkwasmPictureRenderer(surface), view);
      view.dom.setScene(sceneView.sceneElement);
      return sceneView;
    });
  }

  @override
  String get rendererTag => 'skwasm';

  static final Map<String, Future<ui.FragmentProgram>> _programs =
      <String, Future<ui.FragmentProgram>>{};

  @override
  void clearFragmentProgramCache() {
    _programs.clear();
  }

  @override
  Future<ui.FragmentProgram> createFragmentProgram(String assetKey) {
    if (_programs.containsKey(assetKey)) {
      return _programs[assetKey]!;
    }
    return _programs[assetKey] = ui_web.assetManager.load(assetKey).then((ByteData data) {
      return SkwasmFragmentProgram.fromBytes(assetKey, data.buffer.asUint8List());
    });
  }

  @override
  ui.LineMetrics createLineMetrics({
    required bool hardBreak,
    required double ascent,
    required double descent,
    required double unscaledAscent,
    required double height,
    required double width,
    required double left,
    required double baseline,
    required int lineNumber,
  }) => SkwasmLineMetrics(
    hardBreak: hardBreak,
    ascent: ascent,
    descent: descent,
    unscaledAscent: unscaledAscent,
    height: height,
    width: width,
    left: left,
    baseline: baseline,
    lineNumber: lineNumber,
  );

  @override
  ui.Image createImageFromImageBitmap(DomImageBitmap imageSource) {
    return SkwasmImage(
      imageCreateFromTextureSource(
        imageSource,
        imageSource.width,
        imageSource.height,
        surface.handle,
      ),
    );
  }

  @override
  FutureOr<ui.Image> createImageFromTextureSource(
    JSAny textureSource, {
    required int width,
    required int height,
    required bool transferOwnership,
  }) async {
    if (!transferOwnership) {
      textureSource = (await createImageBitmap(textureSource, (
        x: 0,
        y: 0,
        width: width,
        height: height,
      ))).toJSAnyShallow;
    }
    return SkwasmImage(
      imageCreateFromTextureSource(textureSource as JSObject, width, height, surface.handle),
    );
  }

  String _generateDebugFilename(String filePrefix) {
    final now = DateTime.now();
    final String y = now.year.toString().padLeft(4, '0');
    final String mo = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    final String h = now.hour.toString().padLeft(2, '0');
    final String mi = now.minute.toString().padLeft(2, '0');
    final String s = now.second.toString().padLeft(2, '0');
    return '$filePrefix-$y-$mo-$d-$h-$mi-$s.json';
  }

  void _dumpDebugInfo(String filePrefix, Map<String, dynamic> json) {
    final String jsonString = const JsonEncoder.withIndent(' ').convert(json);
    final blob = createDomBlob([jsonString], {'type': 'application/json'});
    final url = domWindow.URL.createObjectURL(blob);
    final element = domDocument.createElement('a');
    element.setAttribute('href', url);
    element.setAttribute('download', _generateDebugFilename(filePrefix));
    element.click();
  }

  @override
  void dumpDebugInfo() {
    if (kDebugMode) {
      withStackScope((StackScope scope) {
        final Pointer<Uint32> counts = scope.allocUint32Array(28);
        skwasmGetLiveObjectCounts(counts);
        final Map<String, dynamic> countsJson = <String, dynamic>{
          'lineBreakBufferCount': counts[0],
          'unicodePositionBufferCount': counts[1],
          'lineMetricsCount': counts[2],
          'textBoxListCount': counts[3],
          'paragraphBuilderCount': counts[4],
          'paragraphCount': counts[5],
          'strutStyleCount': counts[6],
          'textStyleCount': counts[7],
          'animatedImageCount': counts[8],
          'countourMeasureIterCount': counts[9],
          'countourMeasureCount': counts[10],
          'dataCount': counts[11],
          'colorFilterCount': counts[12],
          'imageFilterCount': counts[13],
          'maskFilterCount': counts[14],
          'typefaceCount': counts[15],
          'fontCollectionCount': counts[16],
          'imageCount': counts[17],
          'paintCount': counts[18],
          'pathCount': counts[19],
          'pictureCount': counts[20],
          'pictureRecorderCount': counts[21],
          'shaderCount': counts[22],
          'runtimeEffectCount': counts[23],
          'stringCount': counts[24],
          'string16Count': counts[25],
          'surfaceCount': counts[26],
          'verticesCount': counts[27],
        };
        _dumpDebugInfo('live_object_counts', countsJson);
      });

      int i = 0;
      for (final view in _sceneViews.values) {
        final Map<String, dynamic>? debugJson = view.dumpDebugInfo();
        if (debugJson != null) {
          _dumpDebugInfo('flutter-scene$i', debugJson);
          i++;
        }
      }
    }
  }

  @override
  void debugClear() {
    // TODO(harryterkelsen): See what needs to be cleaned up for tests and clear
    // it here.
  }
}

class SkwasmPictureRenderer implements PictureRenderer {
  SkwasmPictureRenderer(this.surface);

  SkwasmSurface surface;

  @override
  FutureOr<RenderResult> renderPictures(List<ScenePicture> pictures) =>
      surface.renderPictures(pictures.cast<SkwasmPicture>());

  @override
  ScenePicture clipPicture(ScenePicture picture, ui.Rect clip) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder, clip);
    canvas.clipRect(clip);
    canvas.drawPicture(picture);

    return recorder.endRecording() as ScenePicture;
  }
}
