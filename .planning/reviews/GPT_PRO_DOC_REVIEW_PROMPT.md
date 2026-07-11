# GPT Pro Review Prompt: Drum Lesson OS Planning Docs

> **Historical prompt:** This review brief predates the native local-first cutover. It is retained as review history and is not current project guidance. Use [../README.md](../README.md) to locate the active documents.

아래 자료는 아직 구현 코드가 아니라, 새 프로젝트 초기화를 위해 작성한 GSD 계획 문서입니다. 코드 리뷰가 아니라 **프로젝트 방향, MVP 범위, 요구사항 품질, 로드맵 구조, 리스크, 문서 간 일관성**을 리뷰해 주세요.

## 프로젝트 요약

프로젝트명: Drum Lesson OS

핵심 아이디어: 드럼 강사가 여러 학생의 진도와 학생별 특징을 한눈에 관리할 수 있는 미니 CRM입니다. MVP는 강사 입장에서 학생별 현재 진도, 최근 수업 메모, 약점/특징, 과제 상태, 다음 수업 준비 포인트를 빠르게 확인하고 갱신하는 데 집중합니다.

현재 의도적으로 제외한 범위:

- 학생/학부모용 포털
- 결제/인보이스
- 수업 일정 자동화
- 다중 강사/학원 운영
- 오디오/비디오 분석
- 고정된 전체 드럼 커리큘럼

선택한 방향:

- Instructor-side MVP first
- Progress tracking + student traits 중심
- Next.js App Router, TypeScript, Tailwind CSS v4, shadcn/ui, Prisma, SQLite MVP
- Vertical MVP 방식으로 4개 phase 구성

## 먼저 읽을 파일

다음 순서로 읽어 주세요.

1. `project/AGENTS.md`
2. `project/.planning/PROJECT.md`
3. `project/.planning/REQUIREMENTS.md`
4. `project/.planning/ROADMAP.md`
5. `project/.planning/STATE.md`
6. `project/.planning/config.json`
7. `project/.planning/research/SUMMARY.md`
8. 필요하면 `project/.planning/research/STACK.md`, `FEATURES.md`, `ARCHITECTURE.md`, `PITFALLS.md`

## 리뷰 목표

다음 관점으로 검토해 주세요.

1. MVP 범위가 너무 넓거나 너무 좁지 않은지
2. 핵심 가치와 요구사항이 잘 연결되는지
3. 요구사항이 구체적이고 검증 가능한지
4. ROADMAP의 phase 순서와 dependency가 자연스러운지
5. 각 phase success criteria가 실제 사용자 관점에서 검증 가능한지
6. 요구사항 traceability가 빠짐없이 맞는지
7. 리서치에서 나온 근거가 요구사항/로드맵에 잘 반영됐는지
8. 드럼 레슨 도메인에서 빠진 중요한 MVP 요소가 있는지
9. 구현 전에 미리 정리해야 할 데이터 모델/UX 리스크가 있는지
10. 문서끼리 충돌하거나 애매하게 표현된 부분이 있는지

## 특히 엄격하게 봐야 할 부분

- `ROST-02`, `PROG-03`, `NEXT-04`처럼 dashboard briefing과 관련된 요구사항이 Phase 4까지 밀려도 괜찮은지
- Phase 1에서 sample data를 먼저 넣는 것이 적절한지
- flexible progress model이 MVP에 충분한지, 너무 헐겁지는 않은지
- lesson note, assignment, next lesson plan의 경계가 헷갈리지 않는지
- 학생 특징/약점/학습 스타일을 구조화할 범위가 적절한지
- SQLite MVP가 적절한지, 초기부터 hosted Postgres/Supabase로 가야 할 이유가 있는지
- 학생 데이터/privacy 관련 리스크가 문서상 충분히 반영됐는지

## 비목표

이번 리뷰에서는 다음을 하지 않아도 됩니다.

- 실제 코드 구현 방식 리뷰
- 라이브러리 최신 버전 번호 세부 확인
- 마케팅 문구 개선
- 과도한 v2 기능 제안
- 완전한 ERD 작성

다만, 구현 전에 반드시 결정해야 하는 데이터 모델 이슈가 있으면 지적해 주세요.

## 출력 형식

아래 형식으로 답변해 주세요.

### 총평

짧게 3-5문장으로 전체 판단을 적어 주세요.

### 우선순위별 지적 사항

문제마다 아래 형식을 사용해 주세요.

- **[P0/P1/P2/P3] 제목**
  - 위치: `파일 경로`
  - 문제: 무엇이 문제인지
  - 영향: 그대로 두면 어떤 문제가 생기는지
  - 제안: 어떻게 고치면 좋은지

우선순위 기준:

- P0: 이대로 진행하면 MVP 방향이 크게 틀어짐
- P1: 구현 전에 고치는 게 좋은 핵심 결함
- P2: 품질/명확성을 높이는 개선
- P3: 선택적 개선

### 빠진 요구사항 후보

정말 MVP에 필요하다고 보는 항목만 제안해 주세요. 각 항목마다 왜 v1인지, 아니면 v2인지 구분해 주세요.

### 데이터 모델/UX 리스크

구현 전에 정리하면 좋은 데이터 구조, 편집 흐름, 화면 구조 리스크를 적어 주세요.

### 문서 수정 제안

바로 반영 가능한 문장 또는 항목 단위 수정안을 주세요. 파일 경로를 꼭 붙여 주세요.

### 확인 질문

리뷰 중 판단이 어려운 부분은 추측하지 말고 질문으로 남겨 주세요.

## 리뷰 규칙

- 모든 주장은 가능한 한 파일 경로에 근거해 주세요.
- 문서에 없는 사실을 확정적으로 말하지 마세요.
- 불확실하면 “불확실함”이라고 표시해 주세요.
- 리뷰는 한국어로 작성해 주세요.
- 칭찬보다 결함, 모순, 빠진 결정, 구현 전 리스크를 우선해 주세요.
