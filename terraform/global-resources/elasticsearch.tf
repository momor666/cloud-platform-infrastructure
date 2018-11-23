locals {
  live_domain = "cloud-platform-live"

  allowed_live_ips = {
    "54.229.250.233/32" = "test-1-a"
    "54.229.139.68/32"  = "test-1-b"
    "34.246.149.106/32" = "test-1-c"
    "52.17.133.167/32"  = "live-0-a"
    "34.247.134.240/32" = "live-0-b"
    "34.251.93.81/32"   = "live-0-c"
  }

  audit_domain = "cloud-platform-audit"

  allowed_audit_ips = "${local.allowed_live_ips}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_elasticsearch_domain" "live" {
  domain_name           = "${local.live_domain}"
  elasticsearch_version = "6.2"

  cluster_config {
    instance_type  = "m4.large.elasticsearch"
    instance_count = "3"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "320"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.live_domain}/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": ${jsonencode(keys(local.allowed_live_ips))}
        }
      }
    }
  ]
}
CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${local.live_domain}"
  }
}

resource "aws_elasticsearch_domain" "audit" {
  domain_name           = "${local.audit_domain}"
  elasticsearch_version = "6.2"

  cluster_config {
    instance_type  = "m4.large.elasticsearch"
    instance_count = "3"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "320"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action":[ "es:AddTags",
                "es:ESHttpHead",
                "es:DescribeElasticsearchDomain",
                "es:ESHttpPost",
                "es:ESHttpGet",
                "es:ESHttpPut",
                "es:DescribeElasticsearchDomainConfig",
                "es:ListTags",
                "es:DescribeElasticsearchDomains",
                "es:ListDomainNames",
                "es:ListElasticsearchInstanceTypes",
                "es:DescribeElasticsearchInstanceTypeLimits",
                "es:ListElasticsearchVersions"
      ],
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.audit_domain}/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": ${jsonencode(keys(local.allowed_audit_ips))}
        }
      }
    }
  ]
}
CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${local.audit_domain}"
  }
}