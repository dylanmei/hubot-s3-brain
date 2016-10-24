# Description:
#   Stores the brain in Amazon S3.
#
# Configuration:
#   HUBOT_S3_BRAIN_ACCESS_KEY_ID      - AWS Access Key ID with S3 permissions
#   HUBOT_S3_BRAIN_SECRET_ACCESS_KEY  - AWS Secret Access Key for ID
#   HUBOT_S3_BRAIN_BUCKET             - Bucket to store brain in
#   HUBOT_S3_BRAIN_FILE_PATH          - [Optional] Path/File in bucket to store brain at
#   HUBOT_S3_BRAIN_SAVE_INTERVAL      - [Optional] auto-save interval in seconds
#   HUBOT_S3_BRAIN_ENDPOINT           - [Optional] Alternative S3 API endpoint
#
# Commands:
#
# Notes:
#   Updated version of github.com/github/hubot-scripts/s3-brain.coffee by *IrishStyle*
#
#   Take care if using this brain storage with other brain storages.  Others may
#   set the auto-save interval to an undesireable value.  Since S3 requests have
#   an associated monetary value, this script uses a 30 minute auto-save timer
#   by default to reduce cost.
#
#   It's highly recommended to use an IAM account explicitly for this purpose
#   https://console.aws.amazon.com/iam/home?
#   A sample S3 policy for a bucket named Hubot-Bucket would be
#   {
#      "Statement": [
#        {
#          "Action": [
#            "s3:DeleteObject",
#            "s3:DeleteObjectVersion",
#            "s3:GetObject",
#            "s3:GetObjectAcl",
#            "s3:GetObjectVersion",
#            "s3:GetObjectVersionAcl",
#            "s3:PutObject",
#            "s3:PutObjectAcl",
#            "s3:PutObjectVersionAcl"
#          ],
#          "Effect": "Allow",
#          "Resource": [
#            "arn:aws:s3:::Hubot-Bucket/brain-dump.json"
#          ]
#        }
#      ]
#    }
#
# Author:
#   dylanmei

util = require 'util'
AWS  = require 'aws-sdk'

config = {
  accessKeyId: process.env.HUBOT_S3_BRAIN_ACCESS_KEY_ID || process.env.HUBOT_AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.HUBOT_S3_BRAIN_SECRET_ACCESS_KEY || process.env.HUBOT_AWS_SECRET_ACCESS_KEY
}

AWS.config.update config
AWS.config.apiVersions = {
  s3: '2006-03-01'
}

module.exports = (robot) ->

  loaded            = false
  key               = process.env.HUBOT_S3_BRAIN_ACCESS_KEY_ID
  secret            = process.env.HUBOT_S3_BRAIN_SECRET_ACCESS_KEY
  bucket            = process.env.HUBOT_S3_BRAIN_BUCKET
  file_path         = process.env.HUBOT_S3_BRAIN_FILE_PATH || "brain-dump.json"
  # default to 30 minutes (in seconds)
  save_interval     = process.env.HUBOT_S3_BRAIN_SAVE_INTERVAL || 30 * 60
  s3_endpoint       = process.env.HUBOT_S3_BRAIN_ENDPOINT

  if !key && !secret && !bucket
    throw new Error('S3 brain requires HUBOT_S3_BRAIN_ACCESS_KEY_ID, ' +
      'HUBOT_S3_BRAIN_SECRET_ACCESS_KEY and HUBOT_S3_BRAIN_BUCKET configured')

  save_interval = parseInt(save_interval)
  if isNaN(save_interval)
    throw new Error('HUBOT_S3_BRAIN_SAVE_INTERVAL must be an integer')

  args = {
    params: {Bucket: bucket, Key: file_path},
  }
  if s3_endpoint
    args.endpoint = new AWS.Endpoint(s3_endpoint)
    args.s3ForcePathStyle = true

  s3 = new AWS.S3(args)

  store_brain = (brain_data, callback) ->
    if !loaded
      robot.logger.debug 'Not saving to S3, because not loaded yet'
      return

    params = {
      Body: JSON.stringify(brain_data),
    }
    s3.putObject params, (err, data) ->
      if err
        robot.logger.error util.inspect(err)
      else if data
        robot.logger.debug "Saved brain to s3://#{bucket}/#{file_path}"

      if callback then callback(err, data)

  store_current_brain = () ->
    store_brain robot.brain.data

  s3.getObject {}, (err, data) ->
    # unfortunately S3 gives us a 403 if we have access denied OR
    # the file is simply missing, so no way of knowing if IAM policy is bad
    save_handler = (e, r) ->
      if e then throw new Error("Error contacting S3:\n#{util.inspect(e)}")

    # try to store an empty placeholder to see if IAM settings are valid
    if err then store_brain {}, save_handler

    if data && data.Body
      robot.logger.debug "Found brain at s3://#{bucket}/#{file_path}"
      robot.brain.mergeData JSON.parse(data.Body)
    else
      robot.logger.error util.inspect(err)
      robot.brain.mergeData {}

  robot.brain.on 'loaded', () ->
    loaded = true
    robot.brain.resetSaveInterval(save_interval)
    store_current_brain()

  robot.brain.on 'save', () ->
    store_current_brain()

  robot.brain.on 'close', ->
    store_current_brain()
