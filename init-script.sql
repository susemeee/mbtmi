
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
  user_id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  username VARCHAR(100) NOT NULL UNIQUE,
  -- scrypt
  password VARCHAR(256) NOT NULL,
  -- scrypt salt
  password_salt VARCHAR(256) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mbtmi_test (
  test_id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  managed_by UUID NOT NULL,
  FOREIGN KEY (managed_by) REFERENCES mbtmi_user ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS mbtmi_question (
  question_id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL DEFAULT '',
  question_content TEXT NOT NULL DEFAULT '',
  answer_min_content TEXT NOT NULL DEFAULT '',
  answer_max_content TEXT NOT NULL DEFAULT '',
  answer_affects_mbti mbti_type NOT NULL,
  -- If user answers 'yes' than the score of affects_mbti is added by scale_max.
  -- If user answers 'no' than the score of affects_mbti is added by scale_min.
  scale_min INTEGER NOT NULL,
  scale_max INTEGER NOT NULL,
  test_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (test_id) REFERENCES mbtmi_test ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mbtmi_result (
  result_id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  mbti mbti NOT NULL,
  test_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (test_id) REFERENCES mbtmi_test ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mbtmi_session (
  session_id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  test_id UUID NOT NULL,
  user_id UUID NOT NULL,
  mbti mbti,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (test_id) REFERENCES mbtmi_test ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES mbtmi_user ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mbtmi_session_answer (
  id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL,
  question_id UUID NOT NULL,
  answer INTEGER NOT NULL,
  FOREIGN KEY (session_id) REFERENCES mbtmi_session ON DELETE CASCADE
);

-- DML

DELETE FROM mbtmi_user;
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
  (SELECT user_id FROM mbtmi_user LIMIT 1)
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
  '당신은 커피를 사러 가는 도중에, 오래전에 보고 연락이 끊긴 친구와 우연히 마주쳤습니다.',
  '친구를 본 당신은 어떤 행동을 할까요?',
  '오랜만에 본 친구가 너무 반가워서 붙잡고 근황 이야기를 한다.',
  '매우 반갑지만 짧게 인사만 건네고 갈 길을 간다.',
  'e_or_i',
  -1,
  1,
  (SELECT test_id FROM mbtmi_test LIMIT 1)
);

INSERT INTO mbtmi_question (
  question_content,
  answer_min_content,
  answer_max_content,
  answer_affects_mbti,
  scale_min,
  scale_max,
  test_id
) VALUES (
  '낮선 사람이나 친한 사람과 이야기를 할 때 어떤 이야기를 하는게 편한가요?',
  '오늘 있었던 이야기를 설명해준다.',
  '요즘 드는 생각을 이야기한다.',
  's_or_n',
  -2,
  2,
  (SELECT test_id FROM mbtmi_test LIMIT 1)
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
  '당신은 커피를 사고 나서 집으로 오다가 넘어질뻔 했습니다. 당신은 다행히 다친 곳은 없지만, 커피가 쏟아져버렸습니다.',
  '쏟아진 커피를 봤을 때 먼저 드는 생각은?',
  '하 짜증나.. 이걸 다시 사러 가야하나?',
  '괜히 커피 샀나.. 그럴 수 있지 뭐',
  'j_or_p',
  -1,
  1,
  (SELECT test_id FROM mbtmi_test LIMIT 1)
);

INSERT INTO mbtmi_question (
  question_content,
  answer_min_content,
  answer_max_content,
  answer_affects_mbti,
  scale_min,
  scale_max,
  test_id
) VALUES (
  '만약 당신이 친한 친구가 방금의 당신처럼 커피를 쏟았다면 당신이 친구에게 먼저 드는 생각은?',
  '왜 쏟았대냐? 앞좀 잘 보고 다니지... 아니면 짐을 좀 덜 들고 다니던가 ㅋㅅㅋ',
  '헉 괜찮아? ㅠㅠㅠㅠㅠㅠㅠ 😢😢😢',
  't_or_f',
  -1,
  1,
  (SELECT test_id FROM mbtmi_test LIMIT 1)
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
  '집에 돌아온 당신은 안타깝지만 조별과제를 마무리해야 합니다.',
  '조별과제에서 당신의 역할에 조금 더 가까운 것은?',
  '제시한 방향을 정리해서 제출하는 역할',
  '방향을 제시해서 큰 틀을 잡아주는 역할',
  's_or_n',
  -2,
  2,
  (SELECT test_id FROM mbtmi_test LIMIT 1)
);

INSERT INTO mbtmi_question (
  question_content,
  answer_min_content,
  answer_max_content,
  answer_affects_mbti,
  scale_min,
  scale_max,
  test_id
) VALUES (
  '조별과제를 마치고 나서 당신이 하는 것은?',
  '친구랑 카톡하기',
  '스위치를 켜서 동물의 숲 하기',
  'e_or_i',
  -1,
  1,
  (SELECT test_id FROM mbtmi_test LIMIT 1)
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
  '종강하고 여행을 같이 가기로 한 친구가 여행 계획을 짜자고 합니다.',
  '당신이 먼저 든 생각은?',
  '오 좋은데?',
  '귀찮아',
  'j_or_p',
  -2,
  2,
  (SELECT test_id FROM mbtmi_test LIMIT 1)
);

INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ESTJ입니다.', 'ESTJ는 ESTJ입니다. 여기에는 ESTJ에 대한 설명이 들어가는 자리입니다.', 'ESTJ', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ESTP입니다.', 'ESTP는 ESTP입니다. 여기에는 ESTP에 대한 설명이 들어가는 자리입니다.', 'ESTP', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ESFJ입니다.', 'ESFJ는 ESFJ입니다. 여기에는 ESFJ에 대한 설명이 들어가는 자리입니다.', 'ESFJ', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ESFP입니다.', 'ESFP는 ESFP입니다. 여기에는 ESFP에 대한 설명이 들어가는 자리입니다.', 'ESFP', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ENTJ입니다.', 'ENTJ는 ENTJ입니다. 여기에는 ENTJ에 대한 설명이 들어가는 자리입니다.', 'ENTJ', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ENTP입니다.', 'ENTP는 ENTP입니다. 여기에는 ENTP에 대한 설명이 들어가는 자리입니다.', 'ENTP', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ENFJ입니다.', 'ENFJ는 ENFJ입니다. 여기에는 ENFJ에 대한 설명이 들어가는 자리입니다.', 'ENFJ', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ENFP입니다.', 'ENFP는 ENFP입니다. 여기에는 ENFP에 대한 설명이 들어가는 자리입니다.', 'ENFP', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ISTJ입니다.', 'ISTJ는 ISTJ입니다. 여기에는 ISTJ에 대한 설명이 들어가는 자리입니다.', 'ISTJ', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ISTP입니다.', 'ISTP는 ISTP입니다. 여기에는 ISTP에 대한 설명이 들어가는 자리입니다.', 'ISTP', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ISFJ입니다.', 'ISFJ는 ISFJ입니다. 여기에는 ISFJ에 대한 설명이 들어가는 자리입니다.', 'ISFJ', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 ISFP입니다.', 'ISFP는 ISFP입니다. 여기에는 ISFP에 대한 설명이 들어가는 자리입니다.', 'ISFP', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 INTJ입니다.', 'INTJ는 INTJ입니다. 여기에는 INTJ에 대한 설명이 들어가는 자리입니다.', 'INTJ', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 INTP입니다.', 'INTP는 INTP입니다. 여기에는 INTP에 대한 설명이 들어가는 자리입니다.', 'INTP', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 INFJ입니다.', 'INFJ는 INFJ입니다. 여기에는 INFJ에 대한 설명이 들어가는 자리입니다.', 'INFJ', (SELECT test_id FROM mbtmi_test LIMIT 1));
INSERT INTO mbtmi_result (title, content, mbti, test_id) VALUES ('당신은 INFP입니다.', 'INFP는 INFP입니다. 여기에는 INFP에 대한 설명이 들어가는 자리입니다.', 'INFP', (SELECT test_id FROM mbtmi_test LIMIT 1));
