# The pre-flight check: Security and cost guardrails for IaC

Security and Cost Guardrails for Infrastructure as Code (IaC)
This lab is designed to simulate a real-world scenario. You have inherited a multi-cloud Terraform project that is functional but highly insecure and expensive. Your mission is to implement Shift-Left practices to fix the baseline.

## 🏁 Getting started
1. Clone the repository

    ```bash
    git clone git@github.com:bohdan-slota/tf-workshop.git
    cd tf-workshop
    ```

1. The false sense of security
    
    Before we look at guardrails, let's check if our Terraform code is correct according to standard tools.

    ```bash
    terraform init
    terraform fmt -check
    terraform validate
    ```

1. Initialize the Real Guardrails
    
    Now, let's install the shift-left gate that catches what standard linting misses.

    ```bash
    pre-commit install
    ```
1. Set your Infracost API Key

    1. Go to [Infracost](https://dashboard.infracost.io/).
    1. Login with via Google, Github or with your username and password.
    1. Click on your name, then Org settings.
    1. Open `CLI tokens` tab and copy your key.
    
    ```bash
    export INFRACOST_API_KEY=<YOUR_KEY>
    ```

1. Trigger the Reality Check

    Run the audit to see the invisible risks hiding in your valid code.

    ```bash
    pre-commit run --all-files
    ```

    > Note: The first run will pull Docker images for Checkov and Infracost. This may take 1–2 minutes. You should see multiple FAILURES despite the code being valid.

## 🎯 The Mission: Remediate the Baseline
You must modify `aws_resources.tf` and `azure_resources.tf` to satisfy our guardrails.

### 🛡️ Part 1: Security (Checkov)
The security audit is failing. You must:

* **Close Port 22**: Restrict SSH access from 0.0.0.0/0 to a specific internal CIDR.
* **Lock Storage**: Ensure S3 buckets and Azure Storage accounts have "Public Access Block" enabled.

### 💰 Part 2: Finance (Infracost)
Our project budget is $100.00/month. The baseline is currently estimated at ~$3,000/month.

* **Right-size Instances**: Swap over-provisioned instances (e.g., c5.18xlarge) for dev-friendly types (e.g., t3.micro).

## 🚢 Submission
Once your local checks pass, push your code to a personal branch to trigger the remote pipeline.

1. Create a branch

    ```bash
    git checkout -b [your-name]
    
    # Example
    # git checkout -b bohdan-slota
    ```

1. Commit and Push

    If your guardrails are working, the commit will succeed. If your code is still leaky, the Pre-commit Gate will block you locally.

    ```bash
    git add .
    git commit -m "Remediate security and cost leaks"
    git push origin [your-name]
    ```

1. Verify on GitHub
    1. Navigate to the [Actions](https://github.com/bohdan-slota/tf-workshop/actions) tab in this repository.
    1. Ensure your workflow run turns Green.

## ✅ Success Criteria
The lab is successfully completed when:

1. `terraform validate` returns Success.
1. pre-commit run --all-files returns PASSED for all hooks.
1. The Infracost total monthly estimate is < $100.00.
1. The GitHub Action pipeline for your branch is successful.

## 💡 Pro-Tips
* Checkov Docs: If a check fails (e.g., CKV_AWS_20), Checkov provides a URL in the terminal output with the exact Terraform fix.

* Infracost Breakdown: Run `docker run --rm -v $(pwd):/code -e INFRACOST_API_KEY=${INFRACOST_API_KEY} infracost/infracost:latest breakdown --path /code` to see exactly which resource is eating your budget.

* Manual Trigger: Use `pre-commit run --all-files` to test your fixes without having to attempt a git commit every time.

## 💡 If you're stuck with the fixing terraform code...
You can always find the correct path [here](https://github.com/bohdan-slota/tf-workshop/commit/83ffa7f7907d3609835e714ab9dd94eeb912ae99) :)