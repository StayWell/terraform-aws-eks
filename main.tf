#################################################
# Control Plane
#################################################

resource "aws_eks_cluster" "this" {
  name     = "${var.env}"
  role_arn = "${aws_iam_role.control.arn}"
  version  = "${var.kubernetes_version}"

  vpc_config {
    subnet_ids         = ["${var.subnet_ids}"]
    security_group_ids = ["${aws_security_group.control.id}"]
  }
}

# IAM ###########################################

data "aws_iam_policy_document" "control" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "control" {
  name_prefix        = "${var.env}-eks-control-"
  assume_role_policy = "${data.aws_iam_policy_document.control.json}"
  tags               = "${merge(map("Name", "${var.env}-eks-control"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.control.name}"
}

resource "aws_iam_role_policy_attachment" "service" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.control.name}"
}

# Security Group ################################

resource "aws_security_group" "control" {
  name_prefix = "${var.env}-eks-control-"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(map("Name", "${var.env}-eks-control"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "control_ingress_worker" {
  description              = "EKS worker nodes"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.control.id}"
  source_security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "control_egress_worker" {
  description              = "EKS worker nodes"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.control.id}"
  source_security_group_id = "${aws_security_group.worker.id}"
}

#################################################
# Workers
#################################################

data "aws_ami" "linux" {
  owners      = ["${var.trusted_ami_account}"]
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.linux_ami_prefix}-${var.kubernetes_version}*"]
  }
}

data "aws_region" "this" {}

locals {
  linux_userdata = <<EOF
#!/bin/bash -ex
source /etc/eks/bootstrap.sh ${aws_eks_cluster.this.name}
systemctl restart kubelet
EOF
}

resource "aws_launch_template" "linux" {
  name_prefix            = "${var.env}-eks-linux-"
  image_id               = "${data.aws_ami.linux.image_id}"
  instance_type          = "${var.linux_instance_type}"
  ebs_optimized          = true
  user_data              = "${base64encode(local.linux_userdata)}"
  vpc_security_group_ids = ["${aws_security_group.worker.id}"]
  tags                   = "${merge(map("Name", "${var.env}-eks-linux"), var.tags)}"

  block_device_mappings {
    device_name = "${data.aws_ami.linux.root_device_name}"

    ebs {
      volume_size = "${var.linux_disk_size}"
    }
  }

  iam_instance_profile {
    name = "${aws_iam_instance_profile.this.name}"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "volume"
    tags          = "${merge(map("Name", "${var.env}-eks-linux"), var.tags)}"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = "${merge(map("Name", "${var.env}-eks-linux"), var.tags)}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "linux" {
  name_prefix         = "${var.env}-eks-linux-"
  min_size            = "${var.linux_node_count}"
  max_size            = "${var.linux_node_count}"
  vpc_zone_identifier = ["${var.subnet_ids}"]
  target_group_arns   = ["${var.linux_target_group_arns}"]

  launch_template = {
    id      = "${aws_launch_template.linux.id}"
    version = "$$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# IAM ###########################################

data "aws_iam_policy_document" "worker" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "worker" {
  name_prefix        = "${var.env}-eks-worker-"
  assume_role_policy = "${data.aws_iam_policy_document.worker.json}"
  tags               = "${merge(map("Name", "${var.env}-eks-worker"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.worker.name}"
}

resource "aws_iam_role_policy_attachment" "cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.worker.name}"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.worker.name}"
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.env}-"
  role        = "${aws_iam_role.worker.name}"

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group ################################

resource "aws_security_group" "worker" {
  name_prefix = "${var.env}-eks-worker-"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(map("Name", "${var.env}-eks-worker"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "worker_ingress_self" {
  description       = "self"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.worker.id}"
  self              = true
}

resource "aws_security_group_rule" "worker_ingress_control" {
  description              = "EKS control plane"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.worker.id}"
  source_security_group_id = "${aws_security_group.control.id}"
}

resource "aws_security_group_rule" "worker_egress_all" {
  description       = "internet"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.worker.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}
