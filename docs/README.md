# Introduction
This application provides a secure environment for managing categorized information. It offers granular control over data privacy, allowing users to toggle between AES-encrypted storage and plain-text format. Access control is governed by a strict ownership model: users can exclusively manage entities (categories and items) they have created. The system utilizes a local encrypted database; during the initial setup, users must define a Master Password, which functions as the primary derivation key for both database-level encryption and user-specific data protection.

## 