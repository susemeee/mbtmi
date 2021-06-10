import logging
import os
import uuid
from hashlib import scrypt

import psycopg2
from psycopg2.sql import SQL, Identifier, Literal

from mbtmi.model import MBTMIQuestion, MBTMITest

CONNECTION_URL = "dbname={dbname} user={user} password={password}".format(
    dbname=os.getenv("MBTMI_DB_NAME", "mbtmi"),
    user=os.getenv("MBTMI_DB_USER", "postgres"),
    password=os.getenv("MBTMI_DB_CONNECTION_PASSWORD"),
)


class Database:
    def __init__(self):
        self.connector = psycopg2.connect(CONNECTION_URL)

    def query(self, query, commit=True):
        try:
            cur = self.connector.cursor()
            cur.execute(query)
            if commit:
                self.connector.commit()
            return cur
        except Exception as e:
            logging.exception(e)
            raise e

    def _hash(self, content="", salt=""):
        return scrypt(
            content.encode("utf-8"), salt=salt.encode("utf-8"), n=2 ** 12, r=8, p=1
        ).hex()

    def authenticate_user(self, username="", password=""):
        """
        username과 password를 받아서 user를 인증하여 user_id를 리턴합니다.
        """
        if not username or not password:
            return False

        try:
            row = self.query(
                SQL(
                    """
                    SELECT user_id, password, password_salt FROM mbtmi_user
                    WHERE username={username}
                    """
                ).format(
                    username=Literal(username),
                )
            ).fetchone()

            # incorrect password
            if row[1] != self._hash(password, salt=row[2]):
                return None
            else:
                return row[0]
        except Exception as e:
            logging.exception(e)
            return None

    def register_user(self, username="", password=""):
        """
        username과 password를 받아서 회원 가입을 합니다.
        """
        if not username or not password:
            return False

        salt = str(uuid.uuid4())
        hashed_password = self._hash(password, salt=salt)

        try:
            self.query(
                SQL(
                    """
                    INSERT INTO mbtmi_user (username, password, password_salt)
                    VALUES ({username}, {password}, {salt});
                    """
                ).format(
                    username=Literal(username),
                    password=Literal(hashed_password),
                    salt=Literal(salt),
                )
            )
        except Exception as e:
            logging.exception(e)
            return False
        else:
            return True

    def get_count_of_questions(self, test_id):
        """
        특정 테스트의 질문 갯수를 출력합니다.
        """
        try:
            row = self.query(
                SQL(
                    """
                    SELECT COUNT(*) FROM mbtmi_question
                    WHERE test_id={test_id}
                    """
                ).format(
                    test_id=Literal(test_id),
                )
            ).fetchone()

            return row[0]
        except Exception as e:
            logging.exception(e)
            return None

    def calculate_mbti_score(self, session_id):
        """
        심리테스트 세션의 score를 계산하여 mbti를 업데이트합니다.
        """
        try:
            rows = self.query(
                SQL(
                    """
                    SELECT answer_affects_mbti, SUM(answer) FROM mbtmi_session_answer
                    NATURAL JOIN mbtmi_question
                    WHERE session_id={session_id}
                    GROUP BY answer_affects_mbti;
                    """
                ).format(
                    session_id=Literal(session_id),
                )
            ).fetchall()

            result = []
            for row in rows:
                which, val = row
                if which == "e_or_i":
                    result.append("e" if val < 0 else "i")
                elif which == "s_or_n":
                    result.append("s" if val < 0 else "n")
                elif which == "t_or_f":
                    result.append("t" if val < 0 else "f")
                elif which == "j_or_p":
                    result.append("j" if val < 0 else "p")
                else:
                    # 이 이외의 값은 허용하지 않음.
                    raise ValueError(which)

            mbti = "".join(result).upper()
            self.query(
                SQL(
                    """
                    UPDATE mbtmi_session
                    SET mbti={mbti}
                    WHERE session_id={session_id};
                    """
                ).format(
                    mbti=Literal(mbti),
                    session_id=Literal(session_id),
                )
            )
            return session_id
        except Exception as e:
            logging.exception(e)
            return None

    def create_session(self, test_id, user_id):
        """
        user의 새 심리테스트 세션을 생성합니다.
        """
        try:
            session_id = str(uuid.uuid4())
            self.query(
                SQL(
                    """
                    INSERT INTO mbtmi_session (session_id, test_id, user_id)
                    VALUES ({session_id}, {test_id}, {user_id});
                    """
                ).format(
                    session_id=Literal(session_id),
                    test_id=Literal(test_id),
                    user_id=Literal(user_id),
                )
            )
            return session_id
        except Exception as e:
            logging.exception(e)
            return None

    def update_session_with_answer(self, session_id, question_id, answer):
        """
        user의 심리테스트 세션에서 질문에 대한 답을 업데이트합니다.
        """
        try:
            if answer == "l":
                answer_type = Identifier("scale_min")
            elif answer == "r":
                answer_type = Identifier("scale_max")
            else:
                raise ValueError(answer)

            res = self.query(
                SQL(
                    """
                    UPDATE mbtmi_session_answer SET answer=(
                        SELECT {answer_type} FROM mbtmi_question WHERE question_id={question_id}
                    ) WHERE session_id={session_id} AND question_id={question_id};
                    """
                ).format(
                    answer_type=answer_type,
                    session_id=Literal(session_id),
                    question_id=Literal(question_id),
                    answer=Literal(answer),
                )
            )
            if res.rowcount == 0:
                self.query(
                    SQL(
                        """
                        INSERT INTO mbtmi_session_answer (session_id, question_id, answer)
                        VALUES ({session_id}, {question_id}, (
                            SELECT {answer_type} FROM mbtmi_question WHERE question_id={question_id}
                        ));
                        """
                    ).format(
                        answer_type=answer_type,
                        session_id=Literal(session_id),
                        question_id=Literal(question_id),
                        answer=Literal(answer),
                    )
                )
            return True
        except Exception as e:
            logging.exception(e)
            return False

    def get_session_result(self, session_id):
        """
        가능한 경우 심리테스트 세션의 결과값을 가져옵니다.
        """
        try:
            row = self.query(
                SQL(
                    """
                    SELECT mbtmi_result.title, mbtmi_result.content FROM mbtmi_result
                        INNER JOIN mbtmi_test
                        ON mbtmi_test.test_id=mbtmi_result.test_id
                        WHERE mbti=(
                            SELECT mbti from mbtmi_session WHERE session_id={session_id}
                        );
                    """
                ).format(
                    session_id=Literal(session_id),
                )
            ).fetchone()

            return {
                "title": row[0],
                "content": row[1],
            }
        except Exception as e:
            logging.exception(e)
            return []

    def get_tests(self):
        """
        현재 등록된 심리테스트 목록을 가져옵니다.
        """
        try:
            rows = self.query(
                SQL(
                    """
                    SELECT test_id, title FROM mbtmi_test;
                    """
                )
            ).fetchall()

            return [MBTMITest(id=row[0], title=row[1]) for row in rows]
        except Exception as e:
            logging.exception(e)
            return []

    def _get_questions(self, test_id):
        try:
            rows = self.query(
                SQL(
                    """
                    SELECT question_id, content, question_content, answer_min_content, answer_max_content, test_id FROM mbtmi_question
                    WHERE test_id={test_id}
                    """
                ).format(
                    test_id=Literal(test_id),
                )
            ).fetchall()

            return [
                MBTMIQuestion(
                    id=row[0],
                    content=row[1],
                    question_content=row[2],
                    answer_min_content=row[3],
                    answer_max_content=row[4],
                    test_id=row[5],
                )
                for row in rows
            ]
        except Exception as e:
            logging.exception(e)
            return []

    def get_test(self, test_id, with_questions=True):
        """
        심리테스트 하나를 가져옵니다.
        """
        try:
            row = self.query(
                SQL(
                    """
                    SELECT title from mbtmi_test
                    WHERE test_id={test_id}
                    """
                ).format(
                    test_id=Literal(test_id),
                )
            ).fetchone()

            return MBTMITest(
                id=test_id,
                title=row[0],
                questions=self._get_questions(test_id)
                if with_questions is True
                else None,
            )
        except Exception as e:
            logging.exception(e)
            return None

    def delete_session(self, session_id):
        """
        등록된 심리테스트 결과를 지웁니다.
        """
        try:
            self.query(
                SQL(
                    """
                    DELETE FROM mbtmi_session WHERE session_id={session_id};
                    """
                ).format(
                    session_id=Literal(session_id),
                )
            )
        except Exception as e:
            logging.exception(e)
            return False
        else:
            return True
