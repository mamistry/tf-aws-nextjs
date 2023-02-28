# AWS - Terraform modules: Nextjs with Serverless

## Getting started

- You can follow this <a href="https://www.serverless.com/plugins/serverless-nextjs-plugin">link</a> to setup the serverless build for nextjs
- Make sure within the serverless.yml, set the deploy input to false, so serverless doesn't deploy but only builds the app
- The output of the build should contain 5 folders api-lambda, assets, default-lambda, image-lambda, and regeneration-lambda
- This module accepts the lambda_array as a variable, make sure the array points to the *-lamdba directories
- The s3_files module should contain all the files within the assets directory. You can use this module: hashicorp/dir/template
- Make sure to fill in the other variables as well

## Requirements

- terraform >= 0.14
- make
- aws credentials setup

NOTE: Full examples are in `examples` folder.