resource "aws_lb" "public" {
  name               = "${var.project_name}-public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_public_sg_id]
  subnets            = var.web_subnet_ids
  tags               = { Name = "${var.project_name}-public-alb" }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
  tags = { Name = "${var.project_name}-web-tg" }
}

resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_internal_sg_id]
  subnets            = var.app_subnet_ids
  tags               = { Name = "${var.project_name}-internal-alb" }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-app-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
  tags = { Name = "${var.project_name}-app-tg" }
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 3001
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
