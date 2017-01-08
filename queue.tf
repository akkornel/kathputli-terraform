# vim: ts=2 sw=2 et


# The bootstrap queue holds commands that need to be executed by the bootstrap 
# server.  This covers things like creating new repositories and clusters.
# The visibility timeout is 15 minutes, as commands should execute pretty 
# quickly, but message retention time is two weeks, in case the bootstrap 
# instance is deleted and nobody notices for a while.
resource "aws_sqs_queue" "bootstrap" {
  name       = "bootstrap"
  fifo_queue = "true"

  max_message_size = "65536"

  visibility_timeout_seconds = "900"
  message_retention_seconds  = "1209600"
}
  

# The build queue is used to hold commands to build a new image.  This is a 
# standard queue, but messages stay hidden for up to an hour after reading, in 
# order to allow the requested image build to complete.
resource "aws_sqs_queue" "builder" {
  name       = "builder"
  fifo_queue = "false"

  max_message_size = "65536"

  visibility_timeout_seconds = "3600"
  message_retention_seconds  = "1209600"
}
