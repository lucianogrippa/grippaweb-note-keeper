## Introduction

This application is designed to store categorized information securely. Users have the option to encrypt their data or store it as plain text.
Each user can only handle the categories and items they have created.
The application use encrypt local database, the first login it will ask to insert master password used to encrypt database and data related to your account.


The main components of the application are:

## Group

Defines a logical collection of users.

## Authority
Defines the roles assigned to users. The application includes the following roles:

- <b>ADMIN</b>: Can manage Groups and Users. Regarding data, an Admin can only manage categories and items they created.
- <b>OWNER</b>: Can manage users within their own Group. They can only manage categories and items they created.
- <b>USER</b>: Can only manage categories and items they created.

## User

A User is assigned one authority and belongs to one group. A user can own multiple categories. Users have exclusive access to manage their own categories and items.

## Category
A Category defines a specific set of elements. A category contains one or more Items, and only the owner can manage them.

## Item

An Item represents the specific information stored within a category (e.g., a note or simple text). Users can choose to encrypt the information or leave it as plain text. Only the owner of an item has the permission to manage it.

# Architecture

The application is built on a decoupled Client-Server architecture, leveraging a modern JavaScript stack to ensure high performance and cross-platform availability.

## Backend (RESTful API)

The server-side logic is implemented using <b>Node.js</b>, providing a lightweight and scalable RESTful API.

- <b>Statelessness</b>: The server does not store client sessions, ensuring high scalability.
- <b>Security<b>: Implements authentication and authorization (e.g., JWT) to enforce the role-based access control (ADMIN, OWNER, USER) described in the Introduction.
- <b>Data Persistence</b>: Manages communication with the database and handles encryption/decryption logic where required.

## Frontend (Multi-Platform Client)

To support Web, Mobile, Tablet, and Desktop with a consistent user experience, the frontend is built using a "write once, run anywhere" approach (such as Flutter, React Native, or a Responsive Web App with Electron).
Web & Desktop: A responsive interface that adapts to large screens and mouse/keyboard interactions.
Mobile & Tablet: A touch-optimized UI that scales across different resolutions and orientations.
Communication: The client interacts with the Backend exclusively via HTTP/HTTPS requests, consuming JSON data.

# Database

the below figure depicts the database structure:

![alt text](docs/erd-databse.png)

# Folder Structure

/src: frontend angulkar app

/src-tauri: tauri rust app
-- 
