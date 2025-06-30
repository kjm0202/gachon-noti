import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

class AdfitBannerWidget extends StatefulWidget {
  final String adUnit;
  final double width;
  final double height;

  const AdfitBannerWidget({
    super.key,
    required this.adUnit,
    this.width = 320,
    this.height = 50,
  });

  @override
  State<AdfitBannerWidget> createState() => _AdfitBannerWidgetState();
}

class _AdfitBannerWidgetState extends State<AdfitBannerWidget> {
  late final String tagID;

  @override
  void initState() {
    super.initState();
    tagID = "kakao_adfit_${widget.adUnit.hashCode}";

    print('AdfitBannerWidget: 초기화 시작 - tagID: $tagID');

    // ins 요소만 HTML로 생성 (스크립트는 별도로 처리)
    final insHtml = '''
    <ins class="kakao_ad_area" style="display:none;"
      data-ad-unit="${widget.adUnit}"
      data-ad-width="${widget.width.toString()}"
      data-ad-height="${widget.height.toString()}"></ins>''';

    final fitContainer = web.HTMLDivElement()
      ..style.width = "100%"
      ..style.height = "100%"
      ..innerHTML = insHtml.toJS;

    // 스크립트를 동적으로 생성하고 추가
    final script = web.HTMLScriptElement()
      ..type = 'text/javascript'
      ..src = 'https://t1.daumcdn.net/kas/static/ba.min.js'
      ..async = true;

    fitContainer.appendChild(script);

    print('AdfitBannerWidget: HTML 컨테이너 생성 완료');

    // 스크립트 로딩 이벤트 리스너 추가
    script.addEventListener(
        'load',
        (web.Event event) {
          print('AdfitBannerWidget: ba.min.js 로딩 성공');

          // 스크립트 로딩 후 약간의 지연을 두고 광고 영역 활성화
          //Future.delayed(const Duration(milliseconds: 100), () {
          final insElements =
              fitContainer.querySelectorAll('ins.kakao_ad_area');
          if (insElements.length > 0) {
            final insElement = insElements.item(0) as web.HTMLElement?;
            if (insElement != null) {
              insElement.style.display = 'block';
              print('AdfitBannerWidget: ins 요소 display를 block으로 변경');
            }
          }
          //});
        }.toJS);

    script.addEventListener(
        'error',
        (web.Event event) {
          print('AdfitBannerWidget: ba.min.js 로딩 실패');
        }.toJS);

    // Register the view factory using dart:ui_web
    ui_web.platformViewRegistry.registerViewFactory(tagID, (int viewId) {
      print('AdfitBannerWidget: ViewFactory 호출됨');

      // 스크립트 로딩 확인을 위한 추가 처리
      _checkScriptLoading(fitContainer);

      return fitContainer;
    });

    print('AdfitBannerWidget: ViewFactory 등록 완료');
  }

  void _checkScriptLoading(web.HTMLDivElement container) {
    // 스크립트 요소 확인
    final scripts = container.querySelectorAll('script');
    print('AdfitBannerWidget: ViewFactory에서 스크립트 요소 개수: ${scripts.length}');

    if (scripts.length > 0) {
      final script = scripts.item(0) as web.HTMLScriptElement?;
      if (script != null) {
        print('AdfitBannerWidget: ViewFactory에서 스크립트 src: ${script.src}');
      }
    }

    // ins 요소 확인
    final insElements = container.querySelectorAll('ins.kakao_ad_area');
    print('AdfitBannerWidget: ViewFactory에서 ins 요소 개수: ${insElements.length}');
  }

  @override
  Widget build(BuildContext context) {
    print('AdfitBannerWidget: build 호출됨');
    return Center(
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: HtmlElementView(viewType: tagID),
      ),
    );
  }
}
