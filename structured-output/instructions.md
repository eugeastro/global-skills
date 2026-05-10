# structured-output

## 역할

자유 형식 텍스트를 **고정된 JSON schema**에 맞춰 변환한다.
agent 시스템 / 다른 skill의 출력 안정화 핵심 도구.

## 입력

- `content`: 변환 대상 텍스트 (필수)
- `schema`: 목표 JSON schema 객체 (필수)
- `strict`: schema 준수 강제 여부 (기본 `true`)

## 출력

오직 schema에 정의된 JSON 객체만. 코드펜스(```json)도 추가 텍스트도 없음.

## 처리 원칙

1. **schema에 있는 필드만** 출력. 추가 필드 금지.
2. **원본에 없는 정보**는 채우지 말 것 — 모르면 `null` 또는 빈 배열.
3. 타입 엄수: `string`은 string, `number`는 number. 문자열로 감싸지 말 것.
4. enum은 schema 정의된 값만 사용.
5. 필수(required) 필드 추출 불가 → strict=true면 에러 객체 반환.

## 출력 포맷

성공:
```json
{ ... 입력 schema에 맞춘 객체 ... }
```

실패 (strict=true 변환 불가):
```json
{
  "error": "extraction_failed",
  "reason": "...",
  "missing_required_fields": ["..."]
}
```

## 경계

| 한다 | 안 한다 |
|------|---------|
| schema 준수, 타입 검증, 결측 처리 | schema 추천, 필드 추가, 의미 보강 |

요약·번역·추론은 다른 skill에서 먼저 처리한 뒤 이 skill로 **마지막에** 통과시킬 것.

## 처리 순서

1. content 파싱 → 후보 값 추출
2. schema와 매칭 (타입 / 필수 여부 검증)
3. 누락 필드 → null 또는 에러
4. JSON only 출력 (이외 텍스트 금지)

## 실패 모드

- schema 자체가 잘못된 형식 → `{"error": "invalid_schema", ...}`
- content가 schema와 무관 → `{"error": "extraction_failed", ...}`
- LLM이 무심코 markdown 펜스 추가 → 재시도 (raw JSON만)
