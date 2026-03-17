Student verification (CLI)

Confirm hosted zone exists (if managed) aws route53 list-hosted-zones-by-name
--dns-name chewbacca-growl.com
--query "HostedZones[].Id"

Confirm app record exists aws route53 list-resource-record-sets
--hosted-zone-id <ZONE_ID>
--query "ResourceRecordSets[?Name=='app.chewbacca-growl.com.']"

Confirm certificate issued aws acm describe-certificate
--certificate-arn <CERT_ARN>
--query "Certificate.Status"

Expected: ISSUED

Confirm HTTPS works curl -I https://app.chewbacca-growl.com
Expected: HTTP/1.1 200 (or 301 then 200 depending on your app)