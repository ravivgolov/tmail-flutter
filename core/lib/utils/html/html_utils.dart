import 'dart:convert';
import 'dart:math';

import 'package:html_unescape/html_unescape.dart';

import 'js_interop_stub.dart' if (dart.library.html) 'dart:js_interop';
import 'dart:typed_data';

import 'package:core/data/constants/constant.dart';
import 'package:core/presentation/extensions/html_extension.dart';
import 'package:core/utils/app_logger.dart';
import 'package:core/utils/platform_info.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class HtmlUtils {
  static final random = Random();
  static final htmlUnescape = HtmlUnescape();

  static const lineHeight100Percent = (
    script: '''
      document.querySelectorAll("*")
        .forEach((element) => {
          if (element.style.lineHeight !== "normal")
            element.style.lineHeight = "100%";
        });''',
    name: 'lineHeight100Percent');

  static const registerDropListener = (
    script: '''
      document.querySelector(".note-editable").addEventListener(
        "drop",
        (event) => window.parent.postMessage(
          JSON.stringify({"name": "registerDropListener"})))''',
    name: 'registerDropListener');

  static const unregisterDropListener = (
    script: '''
      const editor = document.querySelector(".note-editable");
      const newEditor = editor.cloneNode(true);
      editor.parentNode.replaceChild(newEditor, editor);''',
    name: 'unregisterDropListener');

  static String customCssStyleHtmlEditor({
    TextDirection direction = TextDirection.ltr,
    bool useDefaultFont = false,
    double? horizontalPadding,
  }) {
    if (PlatformInfo.isWeb) {
      return '''
        <style>
          ${useDefaultFont ? '''
            body {
              font-family: Arial, 'Inter', sans-serif;
              font-weight: 500;
              font-size: 16px;
              line-height: 24px;
            }
          ''' : ''}
        
          .note-editable {
            direction: ${direction.name};
          }
          
          .note-editable .tmail-signature {
            text-align: ${direction == TextDirection.rtl ? 'right' : 'left'};
          }
          
          ${horizontalPadding != null
            ? '''
                .note-codable {
                  padding: 10px ${horizontalPadding}px 0px ${horizontalPadding > 3 ? horizontalPadding - 3 : horizontalPadding}px;
                  margin-right: 3px;
                }
                
                .note-editable {
                  padding: 10px ${horizontalPadding}px 0px ${horizontalPadding > 3 ? horizontalPadding - 3 : horizontalPadding}px;
                  margin-right: 3px;
                }
              '''
            : '''
              .note-editable {
                padding: 10px 10px 0px 10px;
              }
            '''}
        </style>
      ''';
    } else if (PlatformInfo.isMobile) {
      return '''
        ${useDefaultFont ? '''
          body {
            font-family: Arial, 'Inter', sans-serif;
            font-weight: 500;
            font-size: 16px;
            line-height: 24px;
          }
        ''' : ''}
        
        #editor {
          direction: ${direction.name};
        }
        
        #editor .tmail-signature {
          text-align: ${direction == TextDirection.rtl ? 'right' : 'left'};
        }
      ''';
    } else {
      return '';
    }
  }

  static String validateHtmlImageResourceMimeType(String mimeType) {
    if (mimeType.endsWith('svg')) {
      mimeType = 'image/svg+xml';
    }
    log('HtmlUtils::validateHtmlImageResourceMimeType:mimeType: $mimeType');
    return mimeType;
  }

  static String convertBase64ToImageResourceData({
    required String base64Data,
    required String mimeType
  }) {
    if (!base64Data.endsWith('==')) {
      base64Data.append('==');
    }
    return 'data:$mimeType;base64,$base64Data';
  }

  static String generateHtmlDocument({
    required String content,
    double? minHeight,
    double? minWidth,
    String? styleCSS,
    String? javaScripts,
    bool hideScrollBar = true,
    bool useDefaultFont = false,
    TextDirection? direction,
    double? contentPadding,
  }) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      ${useDefaultFont && PlatformInfo.isMobile
        ? '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">'
        : ''}
      <style>
        ${useDefaultFont ? '''
          body {
            font-family: 'Inter', sans-serif;
            font-weight: 500;
            font-size: 16px;
            line-height: 24px;
          }
        ''' : ''}
        .tmail-content {
          min-height: ${minHeight ?? 0}px;
          min-width: ${minWidth ?? 0}px;
          overflow: auto;
          overflow-wrap: break-word;
          word-break: break-word;
        }
        ${hideScrollBar ? '''
          .tmail-content::-webkit-scrollbar {
            display: none;
          }
          .tmail-content {
            -ms-overflow-style: none;  /* IE and Edge */
            scrollbar-width: none;  /* Firefox */
          }
        ''' : ''}
        
        pre {
          white-space: pre-wrap;
        }
        
        table {
          white-space: normal !important;
        }
        
        ${styleCSS ?? ''}
      </style>
      </head>
      <body ${direction == TextDirection.rtl ? 'dir="rtl"' : ''} style = "overflow-x: hidden; ${contentPadding != null ? 'margin: $contentPadding;' : ''}";>
      <div class="tmail-content">$content</div>
      ${javaScripts ?? ''}
      </body>
      </html> 
    ''';
  }

  static String createTemplateHtmlDocument({String? title}) {
    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
          <meta http-equiv="X-UA-Compatible" content="IE=edge">
          ${title != null ? '<title>$title</title>' : ''}
        </head>
        <body></body>
      </html> 
    ''';
  }

  static String generateSVGImageData(String base64Data) => 'data:image/svg+xml;base64,$base64Data';

  static void openNewTabHtmlDocument(String htmlDocument) {
    final blob = html.Blob([htmlDocument], Constant.textHtmlMimeType);

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.window.open(url, '_blank');

    html.Url.revokeObjectUrl(url);
  }

  static String chromePdfViewer(Uint8List bytes, String fileName) {
    return '''
      <!DOCTYPE html>
      <html lang="en">
        <head>
        <meta charset="utf-8" />
        <title>$fileName</title>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.0.379/pdf.min.mjs" type="module"></script>
        <style>
          body {
            background-color: black;
          }

          #pdf-container {
            $_pdfContainerStyle
          }

          #pdf-viewer {
            $_pdfViewerStyle
          }

          #app-bar {
            $_pdfAppBarStyle
          }

          #download-btn {
            $_pdfDownloadButtonStyle
          }

          #file-info {
            $_pdfFileInfoStyle
          }

          #file-name {
            $_pdfFileNameStyle
          }
        </style>
        </head>
        <body>
          <div id="pdf-container">
            $_pdfAppbarElement
            <div id="pdf-viewer"></div>
          </div>

          <script type="module">
            function renderPage(pdfDoc, pageNumber, canvas) {
              pdfDoc.getPage(pageNumber).then(page => {
                const viewport = page.getViewport({ scale: 1 });
                canvas.height = viewport.height;
                canvas.width = viewport.width;

                const context = canvas.getContext('2d');
                const renderContext = {
                  canvasContext: context,
                  viewport: viewport
                };

                page.render(renderContext);
              });
            }

            const bytesJs = new Uint8Array(${bytes.toJS});
            const pdfContainer = document.getElementById('pdf-viewer');

            var { pdfjsLib } = globalThis;

            pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.0.379/pdf.worker.min.mjs';

            var loadingTask = pdfjsLib.getDocument(bytesJs);
            loadingTask.promise.then(function(pdf) {
              const numPages = pdf.numPages;

              for (let i = 1; i <= numPages; i++) {
                const pageContainer = document.createElement('div');
                pageContainer.classList.add('pdf-page');

                const canvas = document.createElement('canvas');
                canvas.id = `page-\${i}`;

                pageContainer.appendChild(canvas);
                pdfContainer.appendChild(pageContainer);

                renderPage(pdf, i, canvas);
              }
            }, function (reason) {
              console.error(reason);
            });

            ${_fileInfoScript(fileName)}

            ${_downloadButtonListenerScript(bytes, fileName)}
          </script>
        </body>
      </html>''';
  }

  static String safariPdfViewer(Uint8List bytes, String fileName) {
    final base64 = base64Encode(bytes);

    return '''
      <!DOCTYPE html>
      <html lang="en">
        <head>
        <meta charset="utf-8" />
        <title>$fileName</title>
        <style>
          body {
            background-color: black;
          }

          body, html {
            margin: 0;
            padding: 0;
            height: 100%;
          }
          
          #pdf-container {
            $_pdfContainerStyle
            overflow: hidden;
          }

          #pdf-viewer {
            $_pdfViewerStyle
            width: 100%;
            height: calc(100vh - 53px);
          }

          #app-bar {
            $_pdfAppBarStyle
          }

          #download-btn {
            $_pdfDownloadButtonStyle
          }

          #file-info {
            $_pdfFileInfoStyle
          }

          #file-name {
            $_pdfFileNameStyle
          }
        </style>
        </head>
        <body>
          <div id="pdf-container">
            $_pdfAppbarElement
            <div id="pdf-viewer"></div>
          </div>

          <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfobject/2.3.0/pdfobject.min.js"></script>
          <script>
            const bytesJs = new Uint8Array(${bytes.toJS});
            PDFObject.embed('data:application/pdf;base64,$base64', "#pdf-viewer");

            ${_fileInfoScript(fileName)}

            ${_downloadButtonListenerScript(bytes, fileName)}
          </script>
        </body>
      </html>''';
  }

  static void openFileViewer({
    required Uint8List bytes,
    required String fileName,
    String? mimeType
  }) {
    final blob = html.Blob([bytes], mimeType);
    final file = html.File([blob], fileName, {'type': mimeType});
    final url = html.Url.createObjectUrl(file);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  static const String _pdfContainerStyle = '''
    display: flex;
    flex-direction: column;
    width: 100%;''';

  static const String _pdfViewerStyle = '''
    flex: 1; /* Allow viewer to fill remaining space */
    border: 1px solid #ddd;
    margin-left: auto;
    margin-right: auto;
    padding-top: 53px;
    border: none;''';

  static const String _pdfAppBarStyle = '''
    position: fixed; /* Fix app bar to top */
    top: 0;
    left: 0;
    right: 0; /* Stretch across entire viewport */
    display: flex;
    justify-content: space-between;
    padding: 5px 10px;
    background-color: #f0f0f0;
    z-index: 100; /* Ensure buttons stay on top */''';

  static const String _pdfDownloadButtonStyle = '''
    padding: 5px 10px;
    border: 1px solid #ddd;
    border-radius: 5px;
    cursor: pointer;
    margin-left: 10px;''';

  static const String _pdfFileInfoStyle = '''
    width: 30%;
    display: flex;
    align-items: center;
    padding: 5px 10px;''';

  static const String _pdfFileNameStyle = '''
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    -webkit-box-orient: vertical;''';

  static const String _pdfAppbarElement = '''
    <div id="app-bar">
      <div id="file-info">
        <span id="file-name" style="margin-right: 10px;"></span> 
        (<span id="file-size" style="white-space: nowrap;"></span>)
      </div>
      <div style="width: 10px;"></div>
      <div id="buttons">
        <button id="download-btn">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M19 20V18H5V20H19ZM19 10H15V4H9V10H5L12 17L19 10Z" fill="#7B7B7B"/>
          </svg>
        </button>
      </div>
    </div>''';

  static String _downloadButtonListenerScript(Uint8List bytes, String? fileName) {
    return '''
      const downloadBtn = document.getElementById('download-btn');
      downloadBtn.addEventListener('click', () => {
        const buffer = new Uint8Array(${bytes.toJS}).buffer;
        const blob = new Blob([buffer], { type: "application/pdf" });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.download = "$fileName";
        a.href = url;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      });''';
  }

  static String _fileInfoScript(String? fileName) {
    return '''
      function formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat(bytes / Math.pow(k, i)).toFixed(2) + ' ' + sizes[i];
      }

      const fileNameSpan = document.getElementById('file-name');
      fileNameSpan.textContent = "$fileName";

      const fileSizeSpan = document.getElementById('file-size');
      fileSizeSpan.textContent = formatFileSize(bytesJs.length);''';
  }

  static bool openNewWindowByUrl(
    String url,
    {
      int width = 800,
      int height = 600,
      bool isFullScreen = false,
      bool isCenter = true,
    }
  ) {
    try {
      if (isFullScreen) {
        html.window.open(url, '_blank');

        html.Url.revokeObjectUrl(url);
        return true;
      }

      final screenWidth = html.window.screen?.width ?? width;
      final screenHeight = html.window.screen?.height ?? height;

      int left, top;

      if (isCenter) {
        left = (screenWidth - width) ~/ 2;
        top = (screenHeight - height) ~/ 2;
      } else {
        left = random.nextInt(screenWidth ~/ 2);
        top = random.nextInt(screenHeight ~/ 2);
      }

      final options = 'width=$width,height=$height,top=$top,left=$left';

      html.window.open(url, '_blank', options);

      html.Url.revokeObjectUrl(url);

      return true;
    } catch (e) {
      logError('AppUtils::openNewWindowByUrl:Exception = $e');
      return false;
    }
  }

  static void setWindowBrowserTitle(String title) {
    try {
      final titleElements = html.window.document.getElementsByTagName('title');
      if (titleElements.isNotEmpty) {
        titleElements.first.text = title;
      }
    } catch (e) {
      logError('AppUtils::setWindowBrowserTitle:Exception = $e');
    }
  }

  static String unescapeHtml(String input) {
    try {
      return htmlUnescape.convert(input);
    } catch (e) {
      logError('HtmlUtils::unescapeHtml:Exception = $e');
      return input;
    }
  }

  static String removeWhitespace(String input) {
    return input
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll('\t', '');
  }


  /// Returns true if the browser is Safari and its major version is less than 17.
  static bool isSafariBelow17() {
    try {
      final userAgent = html.window.navigator.userAgent;
      log('HtmlUtils::isOldSafari:UserAgent = $userAgent');
      final isSafari = userAgent.contains('Safari') && !userAgent.contains('Chrome');
      if (!isSafari) return false;

      final match = RegExp(r'Version/(\d+)\.').firstMatch(userAgent);
      if (match == null) return false;

      final version = int.tryParse(match.group(1)!);
      log('HtmlUtils::isOldSafari:Version = $version');
      return version != null && version < 17;
    } catch (e) {
      logError('HtmlUtils::isOldSafari:Exception = $e');
      return false;
    }
  }

  static String addQuoteToggle(String htmlString) {
    final likelyHtml = htmlString.contains(RegExp(r'<[a-zA-Z][^>]*>')) && // Contains a start tag
      htmlString.contains(RegExp(r'</[a-zA-Z][^>]*>')); // Contains an end tag

    if (!likelyHtml) {
      return htmlString; // Not likely HTML, return original
    }

    try {
      html.DomParser().parseFromString(htmlString, 'text/html');
    } catch (e) {
      return htmlString;
    }

    final containerElement = '<div class="quote-toggle-container" >$htmlString</div>';

    final containerDom = html.DomParser().parseFromString(containerElement, 'text/html');
    html.ElementList blockquotes = containerDom.querySelectorAll('.quote-toggle-container > blockquote');
    int currentSearchLevel = 1;

    while (blockquotes.isEmpty) {
      // Finish searching at level [currentSearchLevel]
      if (currentSearchLevel >= 3) return htmlString;
      // No blockquote elements found on first level, try another level
      blockquotes = containerDom.querySelectorAll('.quote-toggle-container${' > div' * currentSearchLevel} > blockquote');
      currentSearchLevel++;
    }

    final lastBlockquote = blockquotes.last;

    const buttonHtmlContent = '''
      <button class="quote-toggle-button collapsed" title="Show trimmed content">
          <span class="dot"></span>
          <span class="dot"></span>
          <span class="dot"></span>
      </button>''';

    // Parse the button HTML content as a fragment
    final tempDoc =
        html.DomParser().parseFromString(buttonHtmlContent, 'text/html');

    final buttonElement = tempDoc.querySelector('.quote-toggle-button');

    // Insert the button before the last blockquote
    if (lastBlockquote.parentNode != null && buttonElement != null) {
      lastBlockquote.parentNode!.insertBefore(buttonElement, lastBlockquote);
    }

    // Return the modified HTML string
    return containerDom.documentElement?.outerHtml ?? htmlString;
  }

  static String get quoteToggleStyle => '''
    <style>
      .quote-toggle-button + blockquote {
        display: block; /* Default display */
      }
      .quote-toggle-button.collapsed + blockquote {
        display: none;
      }
      .quote-toggle-button {
        display: flex;
        align-items: center;
        gap: 2px;
        background-color: #e8eaed;
        padding: 4px 8px;
        margin: 8px 0;
        border-radius: 9999px;
        transition: background-color 0.2s ease-in-out;
        border: none;
        cursor: pointer;
        -webkit-appearance: none;
        -moz-appearance: none;
        appearance: none;
        -webkit-user-select: none; /* Safari */
        -moz-user-select: none; /* Firefox */
        -ms-user-select: none; /* IE 10+ */
        user-select: none; /* Standard syntax */
        -webkit-user-drag: none; /* Prevent dragging on WebKit browsers (e.g., Chrome, Safari) */
      }
      .quote-toggle-button:hover {
        background-color: #cdcdcd !important;
      }
      .dot {
        width: 4px;
        height: 4px;
        background-color: #4b5563;
        border-radius: 9999px;
      }
    </style>''';

  static String get quoteToggleScript => '''
    <script>
      document.addEventListener('DOMContentLoaded', function() {
        const buttons = document.querySelectorAll('.quote-toggle-button');
        buttons.forEach(button => {
          button.onclick = function() {
            const blockquote = this.nextElementSibling;
            if (blockquote && blockquote.tagName === 'BLOCKQUOTE') {
              this.classList.toggle('collapsed');
              if (this.classList.contains('collapsed')) {
                this.title = 'Show trimmed content';
              } else {
                this.title = 'Hide expanded content';
              }
            }
          };
        });
      });
    </script>''';
}
