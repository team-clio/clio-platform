# Clio Platform

Clio 서비스를 한 환경에서 조합하고 실행하기 위한 통합 저장소입니다. 각 서비스의 소스와 개발 이력은
기존 저장소가 소유하며, 이 저장소는 검증된 서비스 커밋 조합과 공통 실행 구성을 관리합니다.

## 빠른 시작 (배포 이미지)

소스를 받지 않고 배포 이미지로 Clio 전체를 실행합니다. Docker와 OpenAI API 키만 있으면 됩니다.

```bash
curl -fsSL https://raw.githubusercontent.com/team-clio/clio-platform/main/compose.release.yaml -o compose.yaml
echo "OPENAI_API_KEY=sk-..." > .env
docker compose up -d
```

<http://localhost:3000>에서 관리 화면이 열립니다. 처음 실행할 때 임베딩 모델(약 639MB)을 내려받으므로
몇 분 걸립니다. 프로젝트를 만들고 Git 저장소(HTTPS)를 연결하면, 동기화가 끝난 뒤부터 버그 처리가 시작됩니다.

```bash
curl -X POST http://localhost:3000/external-api/v1/projects/1/bugs \
  -H 'content-type: application/json' \
  -d '{"source": "API", "title": "결제 실패", "error_type": "PaymentException",
       "stack_trace": ["PaymentService.approve"], "occurred_at": "2026-10-04T05:00:00Z"}'
```

| 변수 | 기본값 | 설명 |
|---|---|---|
| `OPENAI_API_KEY` | (필수) | LLM 인증 정보 |
| `CLIO_MODEL` | `openai:gpt-4.1-mini` | 모든 에이전트가 쓰는 모델 (`provider:model`) |
| `CLIO_MODEL_BASE_URL` | | OpenAI 호환 엔드포인트 주소 |
| `CLIO_ADMIN_PORT` | `3000` | 관리 화면 포트 |
| `CLIO_VERSION` | `latest` | `ghcr.io/team-clio/*` 이미지 태그 |
| `POSTGRES_PASSWORD` | `clio` | PostgreSQL 비밀번호. 최초 실행 전에만 바꿀 수 있습니다 |

외부에 열리는 포트는 관리 화면 하나입니다. 관리 화면의 Nginx가 `/api`, `/external-api`를 서버로 넘기고,
에이전트 전용 `/internal-api`는 노출하지 않습니다. 에이전트는 `langgraph dev` 서버로 실행되므로
컨테이너를 재시작하면 처리 중이던 요청은 다시 보내야 합니다.

업데이트는 `docker compose pull && docker compose up -d`, 데이터까지 지우려면 `docker compose down -v`입니다.

아래부터는 서비스 소스를 함께 받아 직접 빌드하는 개발용 구성입니다.

## 구성

| 경로 | 역할 |
|---|---|
| `services/clio-admin` | 관리자 웹 애플리케이션 |
| `services/clio-server` | Spring Boot API 서버 |
| `services/clio-agent-graph` | Python 에이전트 그래프 |

세 서비스는 Git submodule로 연결되어 있습니다.

## 처음 받기

```bash
git clone --recurse-submodules <clio-platform-url>
cd clio-platform
```

submodule 없이 먼저 clone했다면 다음 명령으로 초기화합니다.

```bash
git submodule update --init --recursive
```

## 서비스 버전 갱신

각 submodule에서 필요한 브랜치나 커밋을 checkout한 뒤, 루트 저장소에서 변경된 submodule 포인터를
커밋합니다.

```bash
git -C services/clio-server fetch
git -C services/clio-server checkout <branch-or-commit>
git add services/clio-server
git commit -m "chore: clio-server 버전 갱신"
```

## Core stack 실행

Admin, API 서버, PostgreSQL(pgvector)을 함께 실행합니다.

```bash
cp .env.example .env
docker compose up --build -d
docker compose ps
```

- Admin: <http://localhost:3000>
- API Server: <http://localhost:8080>
- PostgreSQL: `localhost:15432`

Admin 컨테이너의 Nginx가 `/api` 요청을 API 서버로 전달합니다. 호스트 포트는 `.env`에서 변경할 수
있습니다.

### Smoke test

전체 요청 경로 `Admin Nginx → API Server → PostgreSQL`을 통해 프로젝트를 생성하고 목록에서 다시
조회합니다.

```bash
./scripts/smoke-test.sh
```

### 종료

```bash
docker compose down
```

데이터 볼륨까지 초기화하려면 명시적으로 다음 명령을 사용합니다.

```bash
docker compose down --volumes
```

## Full stack 실행

Core stack에 Agent Graph, PCM PostgreSQL(pgvector), Ollama embedding server를 추가합니다.

```bash
cp .env.example .env
# .env에 OPENAI_API_KEY 등 사용할 LLM provider credential을 입력합니다.
docker compose --profile full up --build -d
docker compose --profile full ps
```

- Agent Graph API: <http://localhost:2024>
- Agent Graph API 문서: <http://localhost:2024/docs>
- PCM PostgreSQL: `localhost:55432`
- Ollama: <http://localhost:11434>

`CLIO_MODEL`은 `provider:model` 형식이며 기본값은 `openai:gpt-4.1-mini`입니다. 실제 API key는
Git에 포함되지 않는 루트 `.env`에만 저장합니다. Agent Graph 컨테이너는 루트 설정을 받고,
컨테이너 내부에서는 PCM PostgreSQL과 Ollama의 Compose 서비스 이름으로 연결합니다.

## 다음 작업

- CI에서 core stack smoke test를 실행합니다.
- Clio Server와 Agent Graph 사이의 실제 요청 경계를 연결합니다.

## 홈페이지

`site/index.html`은 Clio 소개 페이지입니다. 외부 의존성 없는 정적 HTML 한 장이라 그대로 호스팅하면 됩니다.

## 라이선스

[Apache License 2.0](LICENSE)
