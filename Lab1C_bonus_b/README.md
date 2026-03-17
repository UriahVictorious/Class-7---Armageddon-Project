Verification commands (CLI) for Bonus-B

ALB exists and is active

aws elbv2 describe-load-balancers
--names chewbacca-alb01
--query "LoadBalancers[0].State.Code"

HTTPS listener exists on 443

aws elbv2 describe-listeners
--load-balancer-arn <ALB_ARN>
--query "Listeners[].Port"

Target is healthy

aws elbv2 describe-target-health
--target-group-arn <TG_ARN>

WAF attached

aws wafv2 get-web-acl-for-resource
--resource-arn <ALB_ARN>

Alarm created (ALB 5xx)

aws cloudwatch describe-alarms
--alarm-name-prefix chewbacca-alb-5xx

Dashboard exists

aws cloudwatch list-dashboards
--dashboard-name-prefix chewbacca-alb