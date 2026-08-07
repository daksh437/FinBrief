import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/news_article.dart';
import '../widgets/share_card.dart';

class ShareService {
  ShareService._();

  static Future<void> shareArticle(NewsArticle article) {
    final text = article.url != null ? '${article.title}\n${article.url}' : article.title;
    return SharePlus.instance.share(ShareParams(text: text, subject: article.title));
  }

  static Future<void> shareText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }

  /// Shares an AI summary as an image.
  ///
  /// Text pasted into a chat looks like any other forward. A card with the
  /// headline, the key points and the app's mark is something people actually
  /// forward — and in India that is the main way an app spreads, which is why
  /// this exists at all. It costs nothing to run: the image is rendered on the
  /// phone and never touches the server.
  ///
  /// Falls back to sharing plain text if rendering fails, so the button always
  /// does something.
  static Future<void> shareSummaryCard({
    required BuildContext context,
    required NewsArticle article,
    required String summary,
    List<String> keyPoints = const [],
  }) async {
    try {
      final bytes = await _renderCard(
        context: context,
        card: ShareCard(article: article, summary: summary, keyPoints: keyPoints),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/finbrief_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          // Some targets (email, a few keyboards) ignore the image and take
          // the text, so the link goes along for those.
          text: article.url ?? article.title,
        ),
      );
    } catch (_) {
      await shareArticle(article);
    }
  }

  /// Renders a widget that is not on screen into PNG bytes.
  ///
  /// The widget has to be inserted into the real tree to be laid out and
  /// painted — an Offstage subtree never paints, so capturing it yields
  /// nothing. It is therefore added to the Overlay positioned far off-screen,
  /// captured, and removed. The frame wait is required: the boundary has no
  /// image until it has painted once.
  static Future<Uint8List> _renderCard({
    required BuildContext context,
    required Widget card,
  }) async {
    final overlay = Overlay.of(context);
    final boundaryKey = GlobalKey();

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -ShareCard.width * 2,
        top: 0,
        child: RepaintBoundary(
          key: boundaryKey,
          // MediaQuery is reset so the card renders identically regardless of
          // the user's system font scale — otherwise someone with large text
          // set would share a broken-looking card.
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1)),
            child: Directionality(textDirection: TextDirection.ltr, child: card),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    try {
      // One frame to lay out and paint before the boundary has anything.
      await WidgetsBinding.instance.endOfFrame;

      final render = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (render == null) throw StateError('share card did not render');

      final image = await render.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (data == null) throw StateError('share card produced no bytes');
      return data.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }
}
