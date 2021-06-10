import os
import uuid

from flask import Flask, abort, redirect, request, session, url_for
from flask.templating import render_template

from mbtmi.db import Database

app = Flask(__name__)
db = Database()

app.config["SECRET_KEY"] = os.getenv("MBTMI_SESSION_SECRET_KEY", str(uuid.uuid4()))
app.config["TEMPLATES_AUTO_RELOAD"] = True


@app.route("/")
def main():
    tests = db.get_tests()
    return render_template(
        "views/main.html",
        tests=tests,
        is_logged_in="user" in session,
        message=request.args.get("message"),
    )


@app.route("/signup", methods=["GET", "POST"])
def signup():
    def _show_signup_page(message=None):
        return render_template(
            "views/login.html",
            message=message,
            context="Signup",
            context_url=url_for("signup"),
        )

    if "user" in session:
        return render_template("views/main.html", message="이미 로그인되어 있습니다.")
    elif request.method == "POST":
        signup_result = db.register_user(
            username=request.form.get("username"), password=request.form.get("password")
        )
        if not signup_result:
            return _show_signup_page(message="회원가입에 실패하였습니다.")
        else:
            session["user"] = db.authenticate_user(
                username=request.form.get("username"),
                password=request.form.get("password"),
            )
            return redirect(url_for("main"))
    else:
        return _show_signup_page()


@app.route("/login", methods=["GET", "POST"])
def login():
    def _show_login_page(message=None):
        return render_template(
            "views/login.html",
            message=message,
            context="Login",
            context_url=url_for("login"),
        )

    if request.method == "POST":
        login_result = db.authenticate_user(
            username=request.form.get("username"), password=request.form.get("password")
        )
        if not login_result:
            return _show_login_page(message="로그인에 실패하였습니다.")
        else:
            session["user"] = login_result
            return redirect(url_for("main"))
    else:
        return _show_login_page()


@app.route("/logout")
def logout():
    del session["user"]
    return redirect(url_for("main"))


@app.route("/tests/<test_id>")
def view_test(test_id=""):
    if "user" not in session:
        return redirect(url_for("login", message="로그인이 필요합니다."))

    test = db.get_test(test_id)
    if not test:
        abort(404)
    else:
        q_count = db.get_count_of_questions(test_id)
        return render_template(
            "views/test_view.html",
            test=test,
            q_count=q_count,
            is_logged_in="user" in session,
        )


@app.route("/test-sessions", methods=["POST"])
def submit_test_result(test_session_id=""):
    test_session_id = db.create_session(
        test_id=request.form.get("test_id"), user_id=session.get("user")
    )
    if not test_session_id:
        abort(404)
    else:
        for question_id, answer in request.form.items():
            if question_id != "test_id":
                db.update_session_with_answer(
                    session_id=test_session_id, question_id=question_id, answer=answer
                )

        db.calculate_mbti_score(session_id=test_session_id)
        return redirect(url_for("view_test_result", test_session_id=test_session_id))


@app.route("/test-sessions/<test_session_id>")
def view_test_result(test_session_id=""):
    test_result = db.get_session_result(session_id=test_session_id)
    return render_template(
        "views/test_result.html",
        test_session_id=test_session_id,
        test_result=test_result,
        is_logged_in="user" in session,
    )


@app.route("/test-sessions/<test_session_id>/delete")
def delete_test_result(test_session_id=""):
    test_result = db.delete_session(session_id=test_session_id)
    if test_result:
        return redirect(url_for("main", message="테스트 결과를 삭제하였습니다."))
    else:
        return redirect(url_for("main", message="테스트 결과 삭제에 실패하였습니다."))


@app.errorhandler(404)
def page_not_found(e):
    return render_template("views/404.html"), 404
