#!/bin/bash

aws_region="eu-west-1"
my_cluster="ebpf-cilium-xx"
account_id="xxxxx"
vpc_id="vpc-xxxxxxx"
#Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf.if [[ $a == true ]] || [[ $b == true ]]; then
case "$aws_region" in
    us-west-*|us-east-*)
        curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy_us-gov.json
        ;;
    *)
        curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json
        ;;
esac


aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

eksctl utils associate-iam-oidc-provider --region=$aws_region --cluster=$my_cluster --approve
sleep 10

eksctl create iamserviceaccount \
  --cluster=$my_cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$account_id:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

sleep 30

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=ebpf-cilium-6222 \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set vpcId=$vpc_id \
  --set region=$aws_region
