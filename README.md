# Clio Platform

Clio 서비스를 한 환경에서 조합하고 실행하기 위한 통합 저장소입니다. 각 서비스의 소스와 개발 이력은
기존 저장소가 소유하며, 이 저장소는 검증된 서비스 커밋 조합과 공통 실행 구성을 관리합니다.

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

## 다음 작업

- `full` profile에 Agent Graph와 PCM PostgreSQL을 추가합니다.
- CI에서 core stack smoke test를 실행합니다.
