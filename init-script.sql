
-- to use uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- DDL

DROP TYPE mbti CASCADE;
DROP TYPE mbti_type CASCADE;
DROP TABLE mbtmi_user CASCADE;
DROP TABLE mbtmi_test CASCADE;
DROP TABLE mbtmi_question CASCADE;
DROP TABLE mbtmi_result CASCADE;
DROP TABLE mbtmi_session CASCADE;
DROP TABLE mbtmi_session_answer CASCADE;

CREATE TYPE mbti AS ENUM (
  'ESTJ',
  'ESTP',
  'ESFJ',
  'ESFP',
  'ENTJ',
  'ENTP',
  'ENFJ',
  'ENFP',
  'ISTJ',
  'ISTP',
  'ISFJ',
  'ISFP',
  'INTJ',
  'INTP',
  'INFJ',
  'INFP'
);

CREATE TYPE mbti_type AS ENUM ('e_or_i', 's_or_n', 't_or_f', 'j_or_p');


CREATE TABLE IF NOT EXISTS mbtmi_user (
  id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  username VARCHAR(100) NOT NULL UNIQUE,
  -- scrypt
  password VARCHAR(256) NOT NULL,
  -- scrypt salt
  password_salt VARCHAR(256) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mbtmi_test (
  id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  managed_by UUID NOT NULL,
  FOREIGN KEY (managed_by) REFERENCES mbtmi_user ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS mbtmi_question (
  id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL DEFAULT '',
  question_content TEXT NOT NULL DEFAULT '',
  answer_min_content TEXT NOT NULL DEFAULT '',
  answer_max_content TEXT NOT NULL DEFAULT '',
  answer_affects_mbti mbti_type NOT NULL,
  -- if 'scales' is not null and greater than 2, the score of affects_mbti question is increased by
  -- scale_min + user_chosen_scale * ((scale_max - scale_min) / scales)
  -- ex: scale_min=-5, scale_max=5, scales=10. User choses 2(second). affects_mbti += -5 + 2 * (10 / 10) = -3
  -- else, the question becomes yes-or-no question.
  -- If user answers 'yes' than the score of affects_mbti is added by scale_max.
  -- If user answers 'no' than the score of affects_mbti is added by scale_min.
  scales INTEGER,
  scale_min INTEGER NOT NULL,
  scale_max INTEGER NOT NULL,
  test_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (test_id) REFERENCES mbtmi_test ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mbtmi_result (
  id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL DEFAULT '',
  mbti mbti NOT NULL,
  test_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (test_id) REFERENCES mbtmi_test ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mbtmi_session (
  id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  test_id UUID NOT NULL,
  user_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (test_id) REFERENCES mbtmi_test ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES mbtmi_user ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mbtmi_session_answer (
  id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL,
  answer INTEGER NOT NULL,
  FOREIGN KEY (session_id) REFERENCES mbtmi_test ON DELETE CASCADE
);

-- DML

DELETE FROM user;
DELETE FROM mbtmi_test;
DELETE FROM mbtmi_question;
DELETE FROM mbtmi_result;
DELETE FROM mbtmi_session;
DELETE FROM mbtmi_session_answer;

INSERT INTO mbtmi_user (
  username,
  password,
  password_salt
) VALUES (
  'testuser',
  -- scrypt(b'password', salt=b'salt', n=2**12, r=8, p=1).hex()
  'e1d96c45c39931fbecda7a37cd6f64e0f43f12dcecce9d66cd3e279ffe603516f356033201f31c656f8966840b9ff3098d48565b8c55c738b3a1b21cca23093e',
  'salt'
);

INSERT INTO mbtmi_test (
  title,
  managed_by
) VALUES (
  '샘플 테스트',
  (SELECT id FROM mbtmi_user LIMIT 1)
);

INSERT INTO mbtmi_question (
  content,
  question_content,
  answer_min_content,
  answer_max_content,
  answer_affects_mbti,
  scale_min,
  scale_max,
  test_id
) VALUES (
  '당신은 갑자기 낮선 사람을 마주쳤습니다.',
  '당신은 낮선 사람에게 말을 걸 것인가요?',
  '말을 걸지 않는다.',
  '말을 건다.',
  'e_or_i',
  -1,
  1,
  (SELECT id FROM mbtmi_test LIMIT 1)
);

INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ESTJ result', 'ESTJ', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ESTP result', 'ESTP', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ESFJ result', 'ESFJ', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ESFP result', 'ESFP', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ENTJ result', 'ENTJ', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ENTP result', 'ENTP', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ENFJ result', 'ENFJ', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ENFP result', 'ENFP', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ISTJ result', 'ISTJ', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ISTP result', 'ISTP', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ISFJ result', 'ISFJ', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('ISFP result', 'ISFP', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('INTJ result', 'INTJ', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('INTP result', 'INTP', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('INFJ result', 'INFJ', (SELECT id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (content, mbti, test_id) VALUES ('INFP result', 'INFP', (SELECT id FROM mbtmi_test LIMIT 1));
