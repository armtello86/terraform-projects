import boto3

# One-time seeder: loads the question bank into DynamoDB.
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("GeekTrivia-Questions")

QUESTIONS = [
    # ---------- AWS ----------
    ("aws", "q01", "Which service is a serverless NoSQL database?",
     ["RDS", "DynamoDB", "Redshift", "Neptune"], 1, "easy"),
    ("aws", "q02", "What does an SQS DLQ store?",
     ["Logs", "Failed messages", "Metrics", "Backups"], 1, "medium"),
    ("aws", "q03", "Which S3 storage class is cheapest for archives?",
     ["Standard", "One Zone-IA", "Glacier Deep Archive", "Intelligent-Tiering"], 2, "easy"),
    ("aws", "q04", "CloudFront uses which AWS feature to read a private S3 bucket?",
     ["Bucket ACL", "OAC", "NAT Gateway", "VPC Peering"], 1, "medium"),
    ("aws", "q05", "Which service routes events on a schedule?",
     ["SNS", "SQS", "EventBridge", "Kinesis"], 2, "easy"),
    ("aws", "q06", "Multi-AZ in RDS is conceptually similar to which Oracle feature?",
     ["RMAN", "Data Guard", "ASM", "Flashback"], 1, "medium"),
    # ---------- Linux ----------
    ("linux", "q01", "Which command shows real-time processes?",
     ["ls", "top", "pwd", "cat"], 1, "easy"),
    ("linux", "q02", "What does chmod 750 give to 'others'?",
     ["rwx", "rw-", "r-x", "no access"], 3, "medium"),
    ("linux", "q03", "Which file stores local DNS overrides?",
     ["/etc/passwd", "/etc/hosts", "/etc/fstab", "/etc/shadow"], 1, "easy"),
    ("linux", "q04", "Which command finds files larger than 100MB?",
     ["grep", "find / -size +100M", "du -sh", "df -h"], 1, "medium"),
    ("linux", "q05", "What does the 'd' mean in drwxr-xr-x?",
     ["device", "directory", "daemon", "disk"], 1, "easy"),
    ("linux", "q06", "Which signal does 'kill' send by default?",
     ["SIGKILL", "SIGTERM", "SIGHUP", "SIGSTOP"], 1, "medium"),
    # ---------- Databases ----------
    ("databases", "q01", "Which Oracle tool handles physical backups?",
     ["Data Pump", "RMAN", "SQL*Loader", "ADDM"], 1, "easy"),
    ("databases", "q02", "What does ACID's 'I' stand for?",
     ["Index", "Isolation", "Integrity", "Instance"], 1, "easy"),
    ("databases", "q03", "A DynamoDB Query needs at minimum the…",
     ["sort key", "partition key", "GSI", "stream"], 1, "medium"),
    ("databases", "q04", "Vertica is what type of database?",
     ["Row-store OLTP", "Columnar analytics", "Key-value", "Graph"], 1, "easy"),
    ("databases", "q05", "Which isolation level allows dirty reads?",
     ["Serializable", "Repeatable Read", "Read Uncommitted", "Read Committed"], 2, "hard"),
    ("databases", "q06", "Oracle's spfile is most similar to AWS RDS…",
     ["Security Groups", "Parameter Groups", "Subnet Groups", "Option Groups"], 1, "medium"),
]

def lambda_handler(event, context):
    with table.batch_writer() as batch:
        for cat, qid, text, options, answer, diff in QUESTIONS:
            batch.put_item(Item={
                "category": cat,
                "question_id": qid,
                "question": text,
                "options": options,
                "answer_index": answer,
                "difficulty": diff,
            })
    return {"loaded": len(QUESTIONS)}
