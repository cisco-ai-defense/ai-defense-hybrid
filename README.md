# AI Defense Hybrid – AWS EKS Templates

This repository contains infrastructure templates to help customers deploy Cisco AI Defense hybrid deployments.

The templates are provided as examples and starting points. You should review and adapt them to match your own security, compliance, and operational requirements.

## Contents

- `aws-eks/`  
  EKS-related configuration and IAM policies (including Bedrock assume-role policies) to support AI Defense workloads.

## Usage

1. Review each template and parameter.
2. Adjust resource names, ARNs, regions, and account IDs as needed.
3. Apply using your preferred tooling (e.g. `kubectl`, Terraform, CloudFormation, or CI/CD pipelines).

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.