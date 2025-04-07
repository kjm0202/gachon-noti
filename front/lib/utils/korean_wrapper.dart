/// 확장 메소드 [wrapped]는 한국어(한글)가 포함된 경우,
/// 각 단어의 글자 사이에 [U+200D] (zero-width joiner)를 삽입하여
/// Flutter의 텍스트 줄바꿈 이슈를 완화하도록 도와줍니다.
///
/// - 한국어(ㄱ-ㅎ, ㅏ-ㅣ, 가-힣)가 전혀 포함되어 있지 않으면 원본 문자열을 그대로 반환합니다.
/// - 각 줄은 줄바꿈 문자('\n')로 분리되며, 각 줄은 다시 공백(' ') 기준으로 단어별로 분리됩니다.
/// - 각 단어에 대해, 만약 단어에 이모지가 포함되어 있다면 변환 없이 원본을 사용합니다.
///   그렇지 않으면, 단어 내의 연속된 비공백 문자 사이에 zero-width joiner(U+200D)를 삽입합니다.
/// - 원래의 공백과 줄바꿈은 그대로 보존됩니다.
///
/// 참고:
///  - [Flutter 텍스트 한국어 줄바꿈 이슈](https://github.com/flutter/flutter/issues/59284)
///  - [No word-breaks for CJK locales](https://github.com/flutter/flutter/issues/19584)
extension WordWrapBreakWord on String {
  // cspell:ignore udfff

  String get wrapped {
    // 한글(자음, 모음 또는 완성된 글자)이 포함되어 있는지 검사합니다.
    if (!contains(RegExp('[ㄱ-ㅎㅏ-ㅣ가-힣]'))) {
      return this;
    }

    // 이모지(emoji)를 검출하는 정규식.
    final emoji = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
    );
    final fullText = StringBuffer();

    // 줄바꿈('\n')을 기준으로 텍스트를 분리합니다.
    final lines = split('\n');
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      // 각 줄을 단어별로 분리합니다.
      final words = lines[lineIndex].split(' ');
      for (var i = 0; i < words.length; i++) {
        // 만약 단어에 이모지가 포함되어 있다면, 해당 단어는 변환 없이 그대로 사용합니다.
        // 그렇지 않으면 [_zwj] 헬퍼 함수를 이용해 단어 내 각 문자 사이에 U+200D를 삽입합니다.
        fullText.write(emoji.hasMatch(words[i]) ? words[i] : _zwj(words[i]));
        // 단어 사이의 공백을 보존합니다.
        if (i < words.length - 1) {
          fullText.write(' ');
        }
      }
      // 줄바꿈을 보존합니다.
      if (lineIndex < lines.length - 1) {
        fullText.write('\n');
      }
    }
    return fullText.toString();
  }
}

/// 단어 내의 연속된 비공백 문자 사이에 zero-width joiner(U+200D)를 삽입합니다.
///
/// 예시:
/// ```dart
/// final result = '안녕하세요'.wrapped;
/// // result: '안\u200D녕\u200D하\u200D세\u200D요'
/// ```
///
/// 참고:
///  - [Zero-width joiner](https://en.wikipedia.org/wiki/Zero-width_joiner)
String _zwj(String word) {
  return word.replaceAllMapped(
    // (\S)(?=\S) : 연속된 비공백 문자 사이를 매칭합니다.
    RegExp(r'(\S)(?=\S)'),
    (match) => '${match[1]}\u200D',
  );
}
