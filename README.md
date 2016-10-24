hubot-s3-brain
--------------

Store the [hubot](http://hubot.github.com) brain in S3.

This is a lightly modified version of [hubot-scripts/s3-brain.coffee](https://github.com/github/hubot-scripts/blob/master/src/scripts/s3-brain.coffee)
by IrishStyle. It has been updated to use the [AWS S3 SDK](http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/S3.html) package.

Take care if using this brain storage with other brain storages.  Others may
set the auto-save interval to an undesireable value.  Since S3 requests have
an associated monetary value, this script uses a 30 minute auto-save timer
by default to reduce cost.

## Installation

In hubot project repo, run:

```
npm install hubot-s3-brain --save
```

Then add hubot-rules to your external-scripts.json:

```
[
  "hubot-s3-brain"
]
```

## Configuration

S3-brain can be configured with environment variables:

- `HUBOT_S3_BRAIN_ACCESS_KEY_ID` AWS Access Key ID with S3 permissions
- `HUBOT_S3_BRAIN_SECRET_ACCESS_KEY` AWS Secret Access Key for ID
- `HUBOT_S3_BRAIN_BUCKET` Bucket to store brain in
- `HUBOT_S3_BRAIN_FILE_PATH` Optional path/file in bucket to store brain at
- `HUBOT_S3_BRAIN_SAVE_INTERVAL` Optional auto-save interval in seconds
- `HUBOT_S3_BRAIN_ENDPOINT` Alternative S3 API endpoint

It's highly recommended to use an IAM account explicitly for this s3-brain.
A sample S3 policy for a bucket named Hubot-Bucket would be:

```
{
   "Statement": [
     {
       "Action": [
         "s3:DeleteObject",
         "s3:DeleteObjectVersion",
         "s3:GetObject",
         "s3:GetObjectAcl",
         "s3:GetObjectVersion",
         "s3:GetObjectVersionAcl",
         "s3:PutObject",
         "s3:PutObjectAcl",
         "s3:PutObjectVersionAcl"
       ],
       "Effect": "Allow",
       "Resource": [
         "arn:aws:s3:::Hubot-Bucket/brain-dump.json"
       ]
     }
   ]
 }
```

