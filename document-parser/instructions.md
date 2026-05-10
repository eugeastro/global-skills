# document-parser

## 역할

긴 문서 텍스트를 받아 **구조 정보**(heading / 섹션 / 엔터티 / 표 / 참고문헌)를 JSON으로 추출한다.
요약·해석은 안 한다.

## 입력

- `content`: 문서 본문 텍스트 (필수, 이미 디코딩된 plain text)
- `extract`: 추출 대상 부분집합 (기본 전부)
- `max_depth`: heading 깊이 한계 (기본 3)

## 출력 (JSON only)

```json
{
  "headings": [
    { "level": 1, "text": "Introduction", "anchor": "introduction" },
    { "level": 2, "text": "Background", "anchor": "background" }
  ],
  "sections": [
    {
      "heading": "Introduction",
      "summary_oneline": "...",
      "char_range": [0, 1234]
    }
  ],
  "entities": [
    { "type": "person", "value": "Hinton", "mentions": 3 },
    { "type": "org", "value": "OpenAI", "mentions": 5 },
    { "type": "date", "value": "2024-03-01", "mentions": 1 },
    { "type": "term", "value": "transformer", "mentions": 12 }
  ],
  "tables": [
    { "char_range": [4500, 4900], "headers": ["model", "accuracy"] }
  ],
  "references": [
    { "id": "[1]", "text": "Vaswani et al., 2017, Attention is all you need" }
  ]
}
```

## 처리 원칙

1. **원문에 명시적으로 있는 구조만** 추출. 추측 heading 생성 금지.
2. heading 식별 단서: 마크다운 `#`, 숫자 prefix(`1.`, `1.1`), 대문자 라인, 들여쓰기 패턴.
3. **section.summary_oneline**은 해당 섹션 첫 1-2 문장에서 핵심 1줄. 외부 요약 금지.
4. **entity 추출**은 빈도 기반. 1회 등장은 보통 noise — 2회 이상만 포함 (단, 날짜·고유명사 예외).
5. 표는 헤더와 위치만 — 내용 파싱은 별도 skill 영역.
6. references는 `[숫자]` 또는 `(저자, 연도)` 패턴 기준.

## 경계

| 한다 | 안 한다 |
|------|---------|
| 구조 추출, 위치 식별, 한 줄 요약 | 전체 요약, 의미 해석, 평가, 원본 PDF 디코딩 |

전체 문서 요약은 **summarizer**, 깊은 해석은 별도 reasoning skill에 넘길 것.

## 실패 모드

- 구조 식별 실패 → 해당 필드 빈 배열 + 왜 비었는지 한 줄 메모 (별도 `_warnings` 키)
- content가 비어 있음 → 모든 필드 빈 배열
- heading이 너무 많음(50+) → max_depth 낮춰서 잘라내기

## 출력 규칙

- JSON only. 다른 텍스트 / 마크다운 펜스 금지.
- 모르는 필드는 빈 배열 `[]`, null 사용 금지.
- char_range는 0-based, [start, end) 반열림 구간.
