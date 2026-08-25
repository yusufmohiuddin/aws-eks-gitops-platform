# Configure the delivery GitHub App

## Purpose

Allow the image-publishing workflow to create a reviewed promotion pull request
without a personal access token. Installation tokens are short-lived and scoped
to this repository.

## One-time configuration

1. Create a GitHub App named for this repository's delivery automation.
2. Disable webhooks; no callback URL is required.
3. Grant repository permissions: **Contents: Read and write** and **Pull
   requests: Read and write**. Grant no organization or account permissions.
4. Install the app only on `aws-eks-gitops-platform`.
5. Create one private key.
6. Store the App ID as repository variable `DELIVERY_APP_ID`.
7. Store the complete private-key PEM as Actions secret
   `DELIVERY_APP_PRIVATE_KEY`, then delete the downloaded local key.

## Verification

Dispatch `application-delivery` after ECR exists. Confirm that it assumes AWS
through OIDC, publishes an immutable digest, and opens a promotion pull request.
Confirm that normal pull-request checks run and that the app cannot access other
repositories.

## Rotation and revocation

Generate a replacement key, update the repository secret, verify one delivery,
then delete the old key. Uninstalling the app immediately revokes its repository
access.
