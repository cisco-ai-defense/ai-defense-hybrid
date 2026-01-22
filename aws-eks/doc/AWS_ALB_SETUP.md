# AWS ALB Controller Deployment

This document covers the steps to deploy AWS ALB controller for AI Defense Hybrid setup.

## Prerequisites

- EKS cluster created with the [configuration file from this repository](../sample-eks-cluster.yaml)
- Helm 3.x installed
- AWS CLI installed
- eksctl installed

## Policy for LB Controller

Download the policy file

```bash
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.17.0/docs/install/iam_policy.json
```

This policy file can only be used for deployment regions except China and US Gov cloud. Refer the upstream documentation to download the policy file for China and US Gov cloud. Installation Guide - AWS Load Balancer Controller 

```bash
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicyForHybrid \
    --policy-document file://iam-policy.json
```
Output:

```json
{
    "Policy": {
        "PolicyName": "AWSLoadBalancerControllerIAMPolicyForHybrid",
        "PolicyId": "xxxxxxxxxxxxxxxx",
        "Arn": "arn:aws:iam::<account-id>:policy/AWSLoadBalancerControllerIAMPolicyForHybrid",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2026-01-14T13:32:23+00:00",
        "UpdateDate": "2026-01-14T13:32:23+00:00"
    }
}
```

## Create Service account for LB controller (IRSA)

Execute below command to create service account for LB controller. 
Make sure to replace `<cluster-name>`, `<region>`, and `<aws-account-id>` with your actual cluster name, region, and AWS account ID.
If you used a different name for the policy, replace `AWSLoadBalancerControllerIAMPolicyForHybrid` with your policy name.
The name of service account is `aws-load-balancer-controller` by default. If you used a different name, replace it accordingly.

```bash
eksctl create iamserviceaccount \
--cluster=<cluster-name> \
--region=<region> \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::<aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicyForHybrid \
--override-existing-serviceaccounts \
--approve
```

## Install LB controller

Add EKS chart repository

```bash
helm repo add eks https://aws.github.io/eks-charts
```

Create CRDs

```bash
curl -o crds.yaml https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml
kubectl apply -f crds.yaml
```

## Install LB controller helm chart

```bash
helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller --install -n kube-system --set clusterName=<cluster-name> --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
```

Output:

```text
NAME: aws-load-balancer-controller
LAST DEPLOYED: Wed Jan 14 19:08:15 2026
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!
```

## Verify LB controller pods are running

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

```text
NAME                                            READY   STATUS    RESTARTS   AGE
aws-load-balancer-controller-79cd5d8bf5-95tlx   1/1     Running   0          4m16s
aws-load-balancer-controller-79cd5d8bf5-t6vd8   1/1     Running   0          4m16s
```