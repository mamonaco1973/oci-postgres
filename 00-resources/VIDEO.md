#OCI #PostgreSQL #Terraform #OracleCloud #pgweb

*Deploy a Private, Managed PostgreSQL on Oracle Cloud with Terraform*

Oracle Cloud will run a fully managed PostgreSQL database for you — the patching, the backups, the storage — but it lives in a private subnet with no public endpoint. So how do you actually connect to it? In this project we deploy that private database with Terraform, and put a small Ubuntu VM running pgweb in a public subnet as the way in: a browser-based client that can reach the database you can't.

The whole thing is one apply. Terraform builds a two-tier VCN — a public subnet for the pgweb VM behind an Internet Gateway, and a private subnet for the PostgreSQL DB System behind a NAT gateway with outbound-only access. Security lists lock port 5432 to the VM subnet alone. On first boot the VM loads the Pagila sample database — a PostgreSQL port of the Sakila movie-rental schema — so there's real data to query the moment it comes up.

From there it's just SQL in the browser: join films to their actors, collapse a whole cast into a single row with an aggregate — real queries against a managed database that never touches the public internet. When you're done, one command tears the entire stack back down.

WHAT YOU'LL LEARN
• Deploying a fully managed, private PostgreSQL DB System on OCI with Terraform
• Designing a two-tier VCN — public and private subnets, Internet and NAT gateways, per-subnet route tables
• Locking database access down with security lists (5432 from the VM subnet only)
• Reaching a private database through a pgweb jump box in a public subnet
• Loading and querying the Pagila sample database straight from the browser
• Handling OCI credentials and generated passwords through Terraform without a vault service

INFRASTRUCTURE DEPLOYED
• A managed OCI PostgreSQL DB System (PostgreSQL 14) in a private subnet — no public endpoint, automated backups
• A two-tier VCN (10.0.0.0/23) with a public subnet and a private subnet
• An Internet Gateway for the public subnet; a NAT gateway for outbound-only access from the private subnet
• Security lists restricting TCP 5432 to the VM subnet, and TCP 80 and 22 to the pgweb VM
• An Ubuntu 24.04 VM running pgweb, preloaded with the Pagila sample database
• Everything provisioned with Terraform in a single apply, torn down with a single command

GitHub
https://github.com/mamonaco1973/oci-postgres

README
https://github.com/mamonaco1973/oci-postgres/blob/main/README.md

TIMESTAMPS
00:00 Introduction
00:42 Architecture
01:54 Deploy It Yourself
02:51 Live Demo
