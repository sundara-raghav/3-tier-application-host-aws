import time
import os
from flask import Blueprint, current_app, jsonify, redirect, render_template, request, session, url_for

bp = Blueprint("main", __name__)


def _get_topics():
    questions = current_app.config.get("QUESTIONS", {})
    return list(questions.keys())


def _get_question_set(topic: str):
    questions = current_app.config.get("QUESTIONS", {})
    return questions.get(topic, {})


def _wants_json() -> bool:
    return request.is_json or request.args.get("format") == "json" or request.accept_mimetypes.best == "application/json"


@bp.route("/", methods=["GET"])
def index():
    topics = _get_topics()
    return render_template("index.html", topics=topics)


@bp.route("/start", methods=["POST"])
def start():
    if _wants_json():
        payload = request.get_json(force=True)
        username = (payload.get("username") or "").strip()
        topic = (payload.get("topic") or "").strip()
        if not username or not topic:
            return jsonify({"error": "username and topic are required"}), 400
        return jsonify({"message": "ok", "username": username, "topic": topic}), 200

    username = request.form.get("username", "").strip()
    topic = request.form.get("topic", "").strip()
    if not username or not topic:
        return redirect(url_for("main.index"))

    session["username"] = username
    session["started_at"] = int(time.time())
    return redirect(url_for("main.quiz", topic=topic))


@bp.route("/quiz/<topic>", methods=["GET"])
def quiz(topic: str):
    question_set = _get_question_set(topic)
    if not question_set:
        return (jsonify({"error": "unknown topic"}), 404) if _wants_json() else redirect(url_for("main.index"))

    if _wants_json():
        return jsonify(
            {
                "topic": topic,
                "title": question_set.get("title", topic.title()),
                "questions": question_set.get("questions", []),
            }
        )

    if not session.get("username"):
        return redirect(url_for("main.index"))

    return render_template(
        "quiz.html",
        topic=topic,
        title=question_set.get("title", topic.title()),
        questions=question_set.get("questions", []),
        username=session.get("username"),
    )


@bp.route("/submit", methods=["POST"])
def submit():
    # JSON mode supports stateless API clients (e.g., S3-hosted frontend)
    if _wants_json():
        payload = request.get_json(force=True)
        topic = payload.get("topic")
        username = (payload.get("username") or "").strip()
        answers = payload.get("answers") or {}
    else:
        if not session.get("username"):
            return redirect(url_for("main.index"))
        topic = request.form.get("topic")
        username = session.get("username")
        answers = {k: v for k, v in request.form.items() if k != "topic"}

    question_set = _get_question_set(topic)
    questions = question_set.get("questions", [])

    score = 0
    normalized_answers = {}
    for q in questions:
        qid = q.get("id")
        correct = q.get("answer")
        user_answer = answers.get(qid)
        normalized_answers[qid] = user_answer
        if user_answer == correct:
            score += 1

    dynamo = current_app.config.get("DYNAMO_SERVICE")
    total = len(questions)
    attempt_id = dynamo.record_attempt(
        username=username,
        topic=topic,
        score=score,
        total=total,
        answers=normalized_answers,
    )
    if _wants_json():
        return jsonify(
            {
                "attempt_id": attempt_id,
                "username": username,
                "topic": topic,
                "score": score,
                "total": total,
            }
        )

    return render_template(
        "result.html",
        username=username,
        topic=topic,
        score=score,
        total=total,
        attempt_id=attempt_id,
    )


@bp.route("/scoreboard", methods=["GET"])
def scoreboard():
    topic = request.args.get("topic")
    dynamo = current_app.config.get("DYNAMO_SERVICE")
    scores = dynamo.top_scores(topic=topic)
    topics = _get_topics()
    if _wants_json():
        response = jsonify({"scores": scores, "topics": topics, "selected_topic": topic})
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
        return response
    return render_template("scoreboard.html", scores=scores, topics=topics, selected_topic=topic)
