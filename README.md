https://velog.io/@sweetykr/Inception

좋아! 이 문서는 42의 **Inception** 프로젝트(도커·도커컴포즈로 WP 스택 만들기)예요. 아래 순서대로 하면 요구사항을 깔끔히 충족할 수 있어요. 핵심 요구사항은 각 단계에 근거를 달아둘게요.&#x20;

# 한눈에 체크리스트

1. **VM 준비**(Debian/Alpine 기반 컨테이너만 사용)
2. **프로젝트 골격**: `Makefile`, `srcs/docker-compose.yml`, 서비스별 Dockerfile들
3. **서비스 3개**: `nginx(443/TLS)`, `wordpress(+php-fpm)`, `mariadb` (각각 전용 컨테이너)
4. **볼륨 2개**: DB 데이터, WP 파일 → `/home/<login>/data` 아래에 바인드
5. **네트워크 1개**: docker network로 3컨테이너 연결(links/host 금지)
6. **도메인**: `login.42.fr` → 로컬 IP로 매핑
7. **보안**: 최신-1의 Debian/Alpine 태그 고정, `latest` 금지, 비밀번호는 env/secret에만
8. **재시작 정책**: crash 시 자동 재시작
9. **Makefile로 전체 빌드·실행** (`docker-compose` 호출)
10. (보너스는 의무 파트 완벽할 때만 평가)

각 항목은 과제 본문 요구: VM에서 진행, docker-compose 필수, 서비스/이미지 이름 규칙, Alpine/Debian 최신-1, 각각 전용 Dockerfile, NGINX가 443 단일 진입점(TLS1.2/1.3), 볼륨 경로·도메인·비번 관리·`latest` 금지·hacky patch 금지 등.&#x20;

---

## 단계별 가이드

### 0) VM 만들기

* 과제는 **반드시 VM 안에서** 진행. Docker도 VM 안에 설치.&#x20;

### 1) 리포/폴더 뼈대 만들기

```
inception/
├─ Makefile
├─ secrets/               # gitignore 대상(비번/자격증명)
│  ├─ db_root_password.txt
│  ├─ db_password.txt
│  └─ credentials.txt
└─ srcs/
   ├─ .env                # 도메인/DB 유저 등(민감값은 secrets로!)
   ├─ docker-compose.yml
   └─ requirements/
      ├─ nginx/
      │  ├─ Dockerfile
      │  ├─ conf/        # nginx.conf, ssl cert/key 위치 등
      │  └─ tools/
      ├─ wordpress/
      │  ├─ Dockerfile
      │  ├─ conf/        # php-fpm.conf 등
      │  └─ tools/       # wp-cli 셋업 스크립트 등
      └─ mariadb/
         ├─ Dockerfile
         ├─ conf/        # my.cnf
         └─ tools/       # init SQL 스크립트
```

문서 예시 구조와 동일 콘셉트(이름/배치 중요).&#x20;

### 2) 호스트 경로 준비(볼륨)

VM 내부에 다음 경로 준비:

```
/home/<login>/data/db
/home/<login>/data/wp
```

과제는 **이 경로에** DB/WP 볼륨을 바인드하라고 명시. `<login>`은 당신의 42 로그인으로.&#x20;

### 3) 도메인 로컬 매핑

* `login.42.fr` → VM의 로컬 IP로 가리키게 `/etc/hosts` 수정(호스트/VM 양쪽 편한 쪽).
  예: `192.168.56.10  <login>.42.fr`
  과제는 도메인을 **로컬 IP로** 가리키라고 요구.&#x20;

### 4) `.env` 작성

민감값은 secrets 파일에 두고, `.env`에는 비민감/일반 변수 위주:

```
DOMAIN_NAME=<login>.42.fr
MYSQL_USER=wpuser
MYSQL_DATABASE=wordpress
# 민감값은 여기에 직접 쓰지 말고 docker secret로 주입 권장
```

문서는 환경변수 사용 **의무**, `.env` 권장, secrets 사용 **강력 권장**이라고 명시.&#x20;

### 5) `docker-compose.yml`

* **필수**: docker-compose 사용, 서비스별 컨테이너/이미지 이름 일치, 사용자 정의 네트워크, `restart: always` 등.
* **금지**: `network_mode: host`, `links`, `image: ...:latest`.
* **포트**: 외부 노출은 **443 하나만**, 진입점은 **nginx 유일**.&#x20;

구성 예(요점만):

```yaml
services:
  nginx:
    build: ./requirements/nginx
    image: nginx        # 서비스명과 동일하게
    container_name: nginx
    ports: ["443:443"]
    depends_on: [wordpress]
    volumes:
      - wp:/var/www/html
      - ./requirements/nginx/conf:/etc/nginx/conf.d
      # cert/key는 secret로 마운트 권장
    restart: always
    networks: [intra]

  wordpress:
    build: ./requirements/wordpress
    image: wordpress
    container_name: wordpress
    environment:
      - WORDPRESS_DB_HOST=mariadb:3306
      - WORDPRESS_DB_NAME=${MYSQL_DATABASE}
      - WORDPRESS_DB_USER=${MYSQL_USER}
      # 비밀번호는 secret 파일로
    secrets:
      - db_password
    volumes:
      - wp:/var/www/html
    depends_on: [mariadb]
    restart: always
    networks: [intra]

  mariadb:
    build: ./requirements/mariadb
    image: mariadb
    container_name: mariadb
    environment:
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
    secrets:
      - db_password
      - db_root_password
    volumes:
      - db:/var/lib/mysql
    restart: always
    networks: [intra]

volumes:
  db:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/db
  wp:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/wp

networks:
  intra: {}

secrets:
  db_password:
    file: ./secrets/db_password.txt
  db_root_password:
    file: ./secrets/db_root_password.txt
```

> 포인트: `:latest` 금지(직접 Dockerfile 빌드), 링크/host 네트워크 금지, 443만 개방, nginx 단일 진입점.&#x20;

### 6) `nginx` Dockerfile & 설정

* 베이스: **Alpine 또는 Debian의 최신-1 안정판**으로 태그 **고정**.
* TLS는 **1.2 또는 1.3만** 허용.
* 443 리슨, 백엔드는 `wordpress:9000`(php-fpm)로 프록시/fastcgi.&#x20;

핵심:

* 자체 서명 인증서 생성(개발 용도) → secret/volume로 마운트.
* `ENTRYPOINT`/`CMD`는 **데몬 포그라운드**로 기동(while-true, sleep, tail -f 등 금지).&#x20;

### 7) `wordpress(+php-fpm)` Dockerfile & 초기화

* Nginx 포함 **금지**(php-fpm만).&#x20;
* php-fpm을 **포그라운드 모드**로 실행(`php-fpm -F`/버전에 맞게).
* `tools/` 스크립트로 최초 부팅 시 wp-cli로 **사이트/관리자 생성**:

  * **관리자 username에 `admin/Admin` 포함 금지**(예: `administrator`도 안 됨).&#x20;
* 웹 루트 `/var/www/html`를 WP 볼륨에 바인드.

### 8) `mariadb` Dockerfile & 초기화

* `mysqld`를 포그라운드로 실행(`--console` 등).
* `tools/`에서 `/var/lib/mysql` 비어있을 때만 DB/사용자/권한 초기화.
* root/user 비밀번호는 **secrets**에서 읽어 env로 주입.

### 9) Docker 이미지 태깅 규칙

* 각 서비스 Dockerfile 빌드 시 이미지 이름을 **서비스명과 동일**하게(`nginx`, `wordpress`, `mariadb`). 과제 명시.&#x20;

### 10) 재시작 정책·헬스체크

* `restart: always`로 crash 시 재기동 요구를 충족. 필요하면 `healthcheck`도 추가.&#x20;

### 11) Makefile

* **루트에 위치**, `make` 한 번으로 전체 세팅(이미지 빌드+컨테이너 기동).&#x20;
  예시 타깃:

```
up:        docker compose -f srcs/docker-compose.yml up -d --build
down:      docker compose -f srcs/docker-compose.yml down -v
build:     docker compose -f srcs/docker-compose.yml build --no-cache
clean:     docker system prune -af
re:        down clean up
```

### 12) 보안·비밀관리

* **Dockerfile에 비밀번호 절대 금지**.
* `.env` 권장, **Docker secrets 강력 권장**.
* secrets/와 `.env`는 **git에 올리지 않기**(유출 시 실패).&#x20;

### 13) 금지 패턴 체크

* `tail -f`, `sleep infinity`, `while true`, 쉘 붙잡기 등 **PID 1 해킹 금지**.
* 컨테이너는 VM이 **아님**: 올바른 데몬 포그라운드 방식 사용.&#x20;

### 14) 네트워크

* 사용자 정의 `docker network` 필수, 서비스는 이름으로 통신.
* `network_mode: host`, `--link/links:` **금지**. `networks:` 키 **반드시 존재**.&#x20;

### 15) 동작 점검

* `https://<login>.42.fr` 접속 → 인증서(자체서명) 경고는 정상, 페이지는 **WP 설치/사이트 접속** 가능해야 함.
* 컨테이너 재시작 시에도 데이터(글/미디어/DB) 유지(바인드 볼륨 확인).

### 16) 보너스(의무 100% 완료 후에만 평가)

* 제안 목록: **Redis 캐시**, **FTP 서버(WP 볼륨)**, **정적 사이트(PHP 제외)**, **Adminer**, 또는 **본인이 유용하다고 판단한 서비스**. 보너스용 포트는 추가 개방 가능.&#x20;

### 17) 제출·평가

* **깃 저장소에만** 있는 파일이 평가 대상. 폴더/파일명 요구사항 준수.&#x20;

---

## 자주 하는 실수 방지 팁

* `image: debian:bookworm`처럼 **정확한 버전 고정**(최신-1 안정판 취지)하고, 직접 Dockerfile로 빌드 → `latest` 쓰지 않기.&#x20;
* 관리자 계정 아이디가 `admin`류 포함되면 **감점/실패**.&#x20;
* `nginx` 외에 다른 서비스 포트 노출/프록시 우회 금지(443 단일 진입점).&#x20;
* 비밀번호·키를 repo에 올리면 **실패**. `.gitignore` 철저히.&#x20;

---

원하면 위 구조로 \*\*스타터 파일(도커파일/컴포즈/Makefile/설정 템플릿)\*\*을 바로 만들어줄게. 원하는 베이스(Alpine vs Debian)만 말해줘!
