import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void registerCameraViewFactory(String viewType, String src) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final img = html.ImageElement()
        ..src = src
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.border = 'none';
      return img;
    },
  );
}

void openInNewTab(String url) {
  html.window.open(url, '_blank');
}
