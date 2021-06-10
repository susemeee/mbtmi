# mbtmi

## Installation

1. `pipenv`를 사용하여 디펜던시를 설치해 주세요.

```shell
pipenv install
```

2. 다음 환경변수를 수정하거나, `db.py` 내의 `CONNECTION_URL`을 수정해 주세요.

- MBTMI_DB_NAME
- MBTMI_DB_USER
- MBTMI_DB_CONNECTION_PASSWORD

3. `init-script.sql`을 통해 테이블 구조 생성 및 샘플 데이터(예제 테스트 포함)를 추가해 주세요.

4. `python run.py`로 실행 가능합니다.
