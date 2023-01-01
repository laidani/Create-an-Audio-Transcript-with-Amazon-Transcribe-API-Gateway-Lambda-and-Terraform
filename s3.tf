resource "aws_s3_bucket" "transcript_bucket" {
  bucket_prefix = "transcript-bucket-"
  force_destroy = true
}