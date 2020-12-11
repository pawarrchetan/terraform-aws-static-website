# Static Website Example

This is the codebase for creating resources for hosting a static website using _AWS S3_, _AWS CloudFront_ and _terraform_

The module creates a fully functional static website.

## Demo
[chetanpawar.cloud](https://www.chetanpawar.cloud)

## Usage

```hcl
module "static-website" {
  source                 = "git::https://github.com/pawarrchetan/terraform-aws-static-website"
  domain_name            = "example.com"
  alternate_domain_names = [test.example.com, abc.example.com]
  zone_id                = "Zxxxxxxx"
}
```

## License

Creative Commons License
The resources created by this terraform module are free to use under MIt license.
This meand that the files can be :
 - Used for personal projects
 - Change them however you like