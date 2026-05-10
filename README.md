# global-skills

LLM 기능을 재사용 가능한 단위(skill)로 분리해 관리하는 **source registry**.
빌드 파이프라인으로 Claude Code의 native skill 시스템에 자동 설치 → harness가 description 매칭으로 라우팅.

## 파이프라인

```text
global-skills/<name>/manifest.json   ─┐
global-skills/<name>/instructions.md ─┴─→ install.ps1 ─→ ~/.claude/skills/<name>/SKILL.md
                                                       └→ <project>/.claude/skills/<name>/SKILL.md (-Target)
```

`SKILL.md` frontmatter의 `description` 필드를 Claude Code harness가 읽어 자동 호출 후보로 삼는다.

## 2계층 구조

```text
C:\Users\cleor\
├─ global-skills/                  ← source 레지스트리 (이 디렉토리)
│  ├─ scripts/
│  │  ├─ validate.ps1
│  │  ├─ install.ps1
│  │  └─ index.ps1
│  ├─ INDEX.md                     ← 자동 생성, 직접 편집 금지
│  ├─ REGISTRY.md                  ← 운영 규칙 / 스키마
│  ├─ summarizer/  (manifest.json + instructions.md)
│  ├─ code-review/
│  ├─ translator/
│  ├─ structured-output/
│  ├─ reasoning-checker/
│  └─ document-parser/
│
├─ .claude/skills/                 ← 빌드 산출물 (install.ps1이 관리, 직접 편집 금지)
│
└─ projects\claudejup\
   ├─ <project>/
   │  └─ .claude/skills/           ← 프로젝트 빌드 산출물 (-Target으로 설치)
   └─ ...
```

## 우선순위

`<project>/.claude/skills/<name>` > `~/.claude/skills/<name>`

Claude Code는 프로젝트 폴더 내 skill을 우선 인식. 같은 이름이면 프로젝트가 이긴다.

## 각 source skill 디렉토리

```text
<skill-name>/
├─ manifest.json      ← 메타데이터 (필수, REGISTRY.md 스키마)
├─ instructions.md    ← SKILL.md 본문이 됨 (필수)
└─ examples/          ← 입출력 예시 (선택)
```

## Quick start

```powershell
# 검증
.\scripts\validate.ps1

# 전체 빌드 → ~/.claude/skills/
.\scripts\install.ps1

# 일부만
.\scripts\install.ps1 -Skills summarizer,code-review

# 프로젝트 타겟
.\scripts\install.ps1 -Target C:\Users\cleor\projects\claudejup\<project>\.claude\skills

# 변경분만 미리보기
.\scripts\install.ps1 -DryRun

# INDEX.md 갱신
.\scripts\index.ps1
```

`install.ps1`은 idempotent — 이미 같은 내용이면 skip.

## 직접 편집 금지

| 파일 | 이유 |
|------|------|
| `~/.claude/skills/<name>/SKILL.md` | install.ps1이 빌드. source는 `global-skills/<name>/` |
| `<project>/.claude/skills/<name>/SKILL.md` | install.ps1 -Target이 빌드 |
| `INDEX.md` | index.ps1이 manifest.json 보고 자동 생성 |

수정하려면 source(`global-skills/<name>/{manifest.json,instructions.md}`) 고치고 install 재실행.

## 라우팅 (Stage 2 도달)

이전 단계는 manual selection 이었지만, 지금은 SKILL.md frontmatter `description`에 trigger phrase를 명시하므로 Claude Code harness가 description 매칭으로 자동 호출.

- Stage 1 (지난): manual skill selection
- **Stage 2 (현재): description-based discovery via Claude Code harness**
- Stage 3 (예정): semantic / embedding router
- Stage 4 (예정): multi-skill orchestration

자세한 운영 규칙은 [REGISTRY.md](REGISTRY.md) 참고. 현재 빌드된 카탈로그는 [INDEX.md](INDEX.md) 참고.
