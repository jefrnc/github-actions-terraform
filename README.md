# terraform-github-actions

This repository has a github action for terraform projects. In case of making a commit in the "main" branch, the terraform apply is executed directly.

If a Pull request is generated from develop to master, add the plan in the same PR.

```yml
name: 'Terraform'

on:
  push:
    branches:
      - main  
  pull_request:

concurrency: terraform-${{ github.ref }}

jobs:
  main:
    name: 'main'
    runs-on: 'ubuntu-latest'

    steps:
    - name: 'checkout'
      uses: 'actions/checkout@v2'

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: eu-west-3

    - name: 'Setup Terraform'
      uses: 'hashicorp/setup-terraform@v1'
      with:
        terraform_version: '0.14.5'

    - name: 'Terraform Init'
      id: init
      run: 'terraform init -input=false'

    - name: 'Terraform Validate'
      id: validate
      run: 'terraform validate -no-color'

    - name: Terraform Plan
      id: plan
      run: terraform plan -no-color -input=false -out terraform.plan

    - name: Store plan
      uses: actions/upload-artifact@v2
      with:
        name: terraform-plan
        path: ./terraform.plan
        if-no-files-found: error

    - name: 'Terraform fmt'
      id: fmt
      run: 'terraform fmt -diff -check'
      continue-on-error: true

    - name: Find Comment
      uses: peter-evans/find-comment@v1
      if: github.event_name == 'pull_request' && always()
      id: fc
      with:
        issue-number: ${{ github.event.pull_request.number }}
        body-includes: "Terraform Format and Style 🖌"

    - name: Add comment
      if: github.event_name == 'pull_request' && always()
      uses: peter-evans/create-or-update-comment@v1
      with:
        comment-id: ${{ steps.fc.outputs.comment-id }}
        issue-number: ${{ github.event.pull_request.number }}
        edit-mode: replace
        body: |
            #### Terraform Format and Style 🖌
            `${{ steps.fmt.outcome }}`
            #### Terraform Initialization ⚙️
            `${{ steps.init.outcome }}`
            #### Terraform Validation 🤖
            ${{ steps.validate.outputs.stdout }}
            #### Terraform Plan 📖
            `${{ steps.plan.outcome }}`
            <details><summary>Show Plan</summary>
            ```terraform\n${{ steps.plan.outputs.stdout }}```
            </details>
        reaction-type: "rocket"
      
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: terraform apply -auto-approve
```
