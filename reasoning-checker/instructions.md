# reasoning-checker

## 역할

주장 / 답변 / 추론에 대해 **논리적 정합성 + 근거 정합성**을 검사한다.
hallucination 줄이는 verification 레이어.

## 입력

- `claim_or_answer`: 검증 대상 (필수)
- `source`: 근거 자료 (선택이지만 강력 권장)
- `question`: 원래 질문 (선택)

## 출력 (고정 포맷)

```markdown
## Verdict
**{supported | partially_supported | unsupported | contradicts}**

## Issues
- [{severity}] {문제 설명}
  - 위치: "{인용된 문장}"
  - 이유: {왜 문제인지}

## Evidence (source 있을 때)
- "{source 인용문}" → 답변의 어느 부분을 뒷받침 / 반박하는지
```

## Verdict 정의

| 값 | 의미 |
|----|------|
| `supported` | source 또는 자명한 논리로 완전히 뒷받침됨 |
| `partially_supported` | 일부만 뒷받침. 일부는 추론·확장 |
| `unsupported` | 근거 없음 (틀렸다는 뜻 아님 — 검증 불가) |
| `contradicts` | source와 직접 모순 |

## 검사 항목

1. **사실 정합성**: source에 있는 사실과 일치하는가
2. **논리 비약**: 전제 → 결론이 타당한가
3. **모순**: 답변 안에서 자기모순 있는가
4. **양화 오류**: "모두 / 항상" 같은 단정이 source 범위를 넘는가
5. **인과 vs 상관**: 인과 주장에 충분한 근거가 있는가
6. **숫자 / 인용**: 수치·인용이 source와 정확히 일치하는가

## 처리 원칙

1. **source 없으면** 외부 지식으로 fact-check 하지 말 것. `unsupported` + "source 필요" 표기.
2. **확신 없으면** `partially_supported` (binary 판정 강요 금지).
3. `unsupported` ≠ `contradicts`. 근거 없음과 틀림을 구분.
4. **답변을 다시 쓰지 말 것**. 검증만 한다.
5. **가치 / 도덕 판단 금지**. 사실·논리만.

## 경계

| 한다 | 안 한다 |
|------|---------|
| 논리 / 사실 / 근거 검증 | 답변 재작성, 가치 판단, source 없는 사실 판정 |

답변을 고치고 싶으면 호출자가 결과를 보고 별도 skill에 넘겨야 한다.

## 실패 모드

- source 없이 외부 지식으로 단정 → 금지
- 모호한 표현을 임의 해석 → 금지
- 답변이 추론 / 의견 영역 (사실 아님) → "검증 대상 아님" 명시
