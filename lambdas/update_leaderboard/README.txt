⚡ Geek Trivia

A trivia game about AWS, Linux and Databases, built 100% serverless and deployed with Terraform. Scores don't get written straight to the database — they go through an asynchronous queue, and the leaderboard rebuilds itself from DynamoDB Streams instead of scanning the table on every page load.

🎮 How to Use the App
Live URL

Open the CloudFront distribution in your browser: https://dXXXXXXXX.cloudfront.net

User Flow
1.- Sign Up — Enter your display name, email, and password (8+ chars). Cognito sends a verification code to your email.
2.- Confirm — Paste the 6-digit code. Your account is activated and a welcome email (via SNS) is sent automatically.
3.- Log In — Use your email and password. The app receives a JWT ID token from Cognito.
4.- Pick a Category — Choose between AWS, Linux, or Databases.
5.- Play — Answer 5 random questions per round. Correct answers are highlighted in green; wrong ones in red.
6.- Submit Score — After the round, your score is queued asynchronously via SQS. You will see ✅ Score queued.
7.- Leaderboard — Click 🏆 to see the global top 10. It updates automatically via DynamoDB Streams.

💻 Tech Stack

CloudFront + S3 (private, OAC) · Cognito User Pool · API Gateway HTTP API with JWT authorizer · 10 Lambda functions (Python 3.14, arm64) · DynamoDB on-demand + Streams · SQS + DLQ · SNS · EventBridge · SSM Parameter Store · KMS CMK · CloudWatch alarms and dashboard · CloudTrail · Terraform with remote state on S3