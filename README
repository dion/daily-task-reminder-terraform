# 🧭 AWS Daily Task Reminders

![Terraform](https://img.shields.io/badge/Terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![DynamoDB](https://img.shields.io/badge/DynamoDB-%2300599C.svg?style=for-the-badge&logo=amazondynamodb&logoColor=white)

A lightweight Terraform setup to deploy a **DynamoDB-based daily task reminder system** on AWS.

---

## 🧰 Prerequisites

Before you begin, make sure you have:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed  
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured (`aws configure`)  
- A valid AWS profile (used below as `tfproject`)  
- An `item.json` file that defines your initial DynamoDB record  

Example `item.json`:
```json
{
  "id": { "S": "1" },
  "task": { "S": "Send daily reminders" },
  "time": { "S": "08:00" }
}
````

---

## 🚀 Deployment Steps

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Apply the Terraform Plan

```bash
terraform apply "myplan"
```

Confirm the changes when prompted.

---

## 🧩 Add Initial Data to DynamoDB

Once deployment completes, insert an initial item into the `DailyReminders` table:

```bash
aws dynamodb put-item \
  --table-name DailyReminders \
  --item file://item.json \
  --region us-west-2 \
  --profile tfproject
```

---

## 📁 Project Structure

```
aws-daily-task-reminders/
├──
    ├── src
        ├── scheduled-event-logger.mjs
├── main.tf
├── variables.tf
├── outputs.tf
├── item.json
└── README.md
```

---

## 🧠 Notes

* Ensure your Terraform state is stored securely (use an S3 backend for production).
* Use `terraform plan -out myplan` before applying changes to review infrastructure modifications.
* To destroy resources:

  ```bash
  terraform destroy
  ```

---

## 🪶 License

This project is licensed under the [MIT License](LICENSE).

---

**Author:** [Dion](https://github.com/dion)
🌐 Built with ❤️ using Terraform + AWS DynamoDB
