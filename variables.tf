variable "domain_name" {
  description = "Domain name for the website (i.e. www.example.com)"
  type        = string
}

variable "alternate_domain_names" {
  type        = list(string)
  description = "Alternate Domain Names for Certificate"
  default     = []
}

variable "zone_id" {
  description = "ID of the Route 53 Hosted Zone in which to create an alias record"
  type        = string
}

variable validate_certificate {
  description = "Boolean value to enable validation of certificate."
  default     = true
  type        = bool
}