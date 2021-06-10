class MBTMITest:
    def __init__(self, id, title, questions=[], managed_by=None):
        self.id = id
        self.title = title
        self.managed_by = managed_by
        self.questions = questions


class MBTMIQuestion:
    def __init__(
        self,
        id,
        content,
        question_content,
        answer_min_content,
        answer_max_content,
        test_id,
        answer_affects_mbti=None,
        scale_min=None,
        scale_max=None,
        scales=None,
    ):
        self.id = id
        self.content = content
        self.question_content = question_content
        self.answer_min_content = answer_min_content
        self.answer_max_content = answer_max_content
        self.answer_affects_mbti = answer_affects_mbti
        self.scale_min = scale_min
        self.scale_max = scale_max
        self.test_id = test_id


class MBTMIResult:
    def __init__(
        self,
        id,
        content,
        mbti,
        test_id,
    ):
        self.id = id
        self.content = content
        self.mbti = mbti
        self.test_id = test_id
