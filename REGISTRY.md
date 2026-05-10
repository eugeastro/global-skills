# Skill Registry — 운영 규칙

## 1. 계층 & 우선순위

| 위치 | 범위 | 우선순위 |
|------|------|---------|
| `global-skills/<name>` | 전 프로젝트 공유 | 낮음 |
| `<project>/.claude/skills/<name>` | 프로젝트 전용 | 높음 (override) |

동일 이름이 양쪽에 있으면 **project가 이긴다**.

## 2. manifest.json 스키마

```json
{
  "name": "skill-name",
  "version": "v1.1",
  "description": "Claude Code skill discovery용 1-3 문장 설명 (선택, 권장). 'Trigger when ...' 문구 포함 권장. 한국어 trigger phrase 같이 넣으면 매칭 잘 됨.",
  "scope": "global | project",
  "purpose": "한 줄 요약",
  "input": {
    "format": "text | json | file",
    "schema": "..."
  },
  "output": {
    "format": "text | json | markdown",
    "schema": "..."
  },
  "dependencies": [],
  "boundaries": {
    "does": ["..."],
    "does_not": ["..."]
  },
  "failure_modes": ["..."]
}
```

`description`은 install.ps1이 SKILL.md frontmatter의 `description:` 필드로 사용. 없으면 `purpose`로 fallback (덜 정확한 매칭).

## 3. 좋은 skill의 기준

- 입력 구조가 명확함
- output format이 고정됨
- 실패 모드가 정의됨
- context dependency 최소화
- 다른 skill과 조합 가능
- **boundary 명확**: 옆 skill 영역 침범 금지
  - summarizer는 reasoning 하지 않음
  - code-review는 architecture 설계까지 안 감
  - translator는 interpretation 하지 않음

## 4. 버전 / 변경 규칙

- skill 수정 시 `manifest.json`의 `version` 갱신 (v1 → v1.1)
- 기존 skill 파일 **덮어쓰기 금지**
- Breaking change는 **새 skill로 분리** (예: `summarizer-v2/`)
- 옛 버전은 deprecation 표시만 하고 일정 기간 유지

## 5. 실행 규칙 (현재 단계)

- 사용자가 skill을 **명시적으로 선택**하거나
- 프로젝트 기본 skill set에 포함된 것만 사용
- 자동 routing / inference **금지** (Stage 2 이후)

## 6. 새 skill 추가 절차

1. 적용 범위 결정 (global vs project)
2. 디렉토리 생성: `<skill-name>/`
3. `manifest.json` 작성 (스키마 준수)
4. `instructions.md` 작성 (prompt 본문)
5. 가능하면 `examples/` 추가
6. boundary가 기존 skill과 겹치지 않는지 검토
7. project 단계 → 충분히 검증되면 global로 승격 검토

## 7. 절대 금지

- skill 안에서 다른 skill 호출 (조합은 호출자 책임)
- prompt 안에 비밀키, 토큰, 개인정보
- silent override (project skill로 덮을 때 README에 명시)
- `~/.claude/skills/<name>/SKILL.md` 직접 수정 (install.ps1이 덮어씀 — source는 항상 `global-skills/<name>/`)
- `INDEX.md` 직접 편집 (index.ps1이 manifest.json 보고 자동 생성)

## 8. 빌드 파이프라인

```text
global-skills/<name>/manifest.json   ─┐
global-skills/<name>/instructions.md ─┴─→ install.ps1 ─→ ~/.claude/skills/<name>/SKILL.md
                                                       └→ <project>/.claude/skills/<name>/SKILL.md (-Target)
```

| 작업 | 명령 |
|------|------|
| 검증 | `.\scripts\validate.ps1` |
| 빌드 / 설치 (global) | `.\scripts\install.ps1` |
| 빌드 / 설치 (project) | `.\scripts\install.ps1 -Target <project>\.claude\skills` |
| 일부만 빌드 | `.\scripts\install.ps1 -Skills summarizer,code-review` |
| Dry run | `.\scripts\install.ps1 -DryRun` |
| 인덱스 갱신 | `.\scripts\index.ps1` (`INDEX.md` 갱신) |

install.ps1은 시작 시 자동으로 validate.ps1을 실행 — 검증 실패 시 빌드 거부 (`-SkipValidate`로 건너뛰기 가능).

PowerShell 실행 정책으로 막히면:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
# 또는 한 번만 (CurrentUser):
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

## 9. 권장 워크플로 (skill 발전시키기)

1. 작은 변경 (프롬프트 다듬기, 새 검사 항목): `manifest.json` version bump v1 → v1.1, `install.ps1` 재실행
2. Breaking change (입출력 schema 깨짐): 새 폴더 (`summarizer-v2/`), 옛 버전은 deprecation 표기 후 일정 기간 유지
3. 프로젝트 단위 실험: `<project>/.claude/skills/<name>/SKILL.md` 직접 만들거나, 프로젝트 안에 `skills-src/<name>/` 두고 같은 install.ps1을 `-Target` 으로 호출
4. 검증된 project skill을 global로 승격: `manifest.json` 통째로 `global-skills/<name>/`로 이동, `scope`를 `project` → `global`로 바꾸고 install
