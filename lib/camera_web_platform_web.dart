import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void registerVideoFeedView(String viewType, String src) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => html.ImageElement()
      ..src = src
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.border = 'none',
  );
}

void openInNewTab(String url) {
  html.window.open(url, '_blank');
}
