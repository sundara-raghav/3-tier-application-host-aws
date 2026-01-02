import json
import os
from pathlib import Path
from flask import Flask, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

from app.routes import bp as main_bp
from app.services.dynamo import DynamoService


def _datetimeformat(ts: int) -> str:
    from datetime import datetime

    try:
        return datetime.utcfromtimestamp(int(ts)).strftime("%Y-%m-%d %H:%M UTC")
    except Exception:
        return "--"


def load_questions(question_file: Path) -> dict:
    """Load questions from local JSON file"""
    if not question_file.exists():
        raise FileNotFoundError(f"Question file not found: {question_file}")
    
    with question_file.open("r", encoding="utf-8") as f:
        data = json.load(f)
        print(f"Loaded {len(data)} topics from {question_file}")
        return data


def create_app() -> Flask:
    load_dotenv()

    app = Flask(__name__, template_folder="templates", static_folder="static")
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev-secret-key")

    # Enable CORS for S3 frontend
    CORS(app, resources={r"/*": {"origins": "*"}})

    aws_region = os.getenv("AWS_REGION", "us-east-1")
    users_table = os.getenv("DYNAMO_USERS_TABLE", "quiz_users")
    scores_table = os.getenv("DYNAMO_SCORES_TABLE", "quiz_scores")

    question_file = Path(os.getenv("QUESTION_FILE", Path(__file__).parent / "data" / "questions.json"))
    app.config["QUESTIONS"] = load_questions(question_file)

    app.config["DYNAMO_SERVICE"] = DynamoService(
        region_name=aws_region,
        users_table=users_table,
        scores_table=scores_table,
    )

    app.jinja_env.filters["datetimeformat"] = _datetimeformat

    app.register_blueprint(main_bp)
    
    # Health check endpoint
    @app.route('/health', methods=['GET'])
    def health():
        """Health check endpoint"""
        return jsonify({
            "status": "healthy",
            "topics_loaded": len(app.config["QUESTIONS"]),
            "topics": list(app.config["QUESTIONS"].keys())
        })

    return app
