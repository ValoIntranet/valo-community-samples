param(
    [string]$domainName
)
Add-DnsServerResourceRecordA -Name "portal2016" -ZoneName $domainName -AllowUpdateAny -IPv4Address "10.11.4.4"
Add-DnsServerResourceRecordA -Name "my2016" -ZoneName $domainName -AllowUpdateAny -IPv4Address "10.11.4.4"
Add-DnsServerResourceRecordA -Name "classic" -ZoneName $domainName -AllowUpdateAny -IPv4Address "10.11.4.4"
Add-DnsServerResourceRecordA -Name "portal2019" -ZoneName $domainName -AllowUpdateAny -IPv4Address "10.11.4.5"
Add-DnsServerResourceRecordA -Name "my2019" -ZoneName $domainName -AllowUpdateAny -IPv4Address "10.11.4.5"
Add-DnsServerResourceRecordA -Name "modern" -ZoneName $domainName -AllowUpdateAny -IPv4Address "10.11.4.5"
Add-DnsServerResourceRecordA -Name "office" -ZoneName $domainName -AllowUpdateAny -IPv4Address "10.0.4.6"
