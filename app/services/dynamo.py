import os
import time
import uuid
from typing import Any, Dict, List, Optional

import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError


class DynamoService:
    def __init__(self, region_name: str, users_table: str, scores_table: str) -> None:
        self.region_name = region_name
        session = boto3.session.Session(
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
            aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
            region_name=region_name,
        )
        self.dynamo = session.resource("dynamodb")
        self.users_table = self.dynamo.Table(users_table)
        self.scores_table = self.dynamo.Table(scores_table)

    def record_attempt(
        self,
        username: str,
        topic: str,
        score: int,
        total: int,
        answers: Optional[Dict[str, Any]] = None,
    ) -> str:
        attempt_id = str(uuid.uuid4())
        now = int(time.time())
        item = {
            "quiz_attempt_id": attempt_id,
            "username": username,
            "topic": topic,
            "score": score,
            "total": total,
            "timestamp": now,
            "answers": answers or {},
        }
        self.users_table.put_item(Item=item)

        # store summarized score for leaderboard; score is padded to keep lexicographic ordering
        score_key = f"{score:04d}#{now}#{attempt_id}"
        score_item = {
            "topic": topic,
            "score_key": score_key,
            "username": username,
            "score": score,
            "total": total,
            "timestamp": now,
        }
        self.scores_table.put_item(Item=score_item)
        return attempt_id

    def top_scores(self, topic: Optional[str] = None, limit: int = 20) -> List[Dict[str, Any]]:
        try:
            if topic:
                resp = self.scores_table.query(
                    KeyConditionExpression=Key("topic").eq(topic),
                    ScanIndexForward=False,
                    Limit=limit,
                )
                items = resp.get("Items", [])
            else:
                scan_resp = self.scores_table.scan(Limit=limit)
                items = scan_resp.get("Items", [])
            # Normalize ordering high-to-low by score
            items = sorted(items, key=lambda i: (i.get("score", 0), i.get("timestamp", 0)), reverse=True)
            return items[:limit]
        except ClientError:
            return []
