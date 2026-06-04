# Deploying PostgreSQL on OCI

This project demonstrates how to deploy a secure, private PostgreSQL DB System on Oracle Cloud Infrastructure using Terraform.

The deployment provisions a fully managed OCI PostgreSQL DB System with no public endpoint, isolated in a private subnet of a custom VCN. To provide convenient browser-based access for database interaction, the project also deploys a lightweight Ubuntu virtual machine running [pgweb](https://github.com/sosedoff/pgweb) in a public subnet.

As part of the setup, the [Pagila](https://github.com/devrimgunduz/pagila) sample database—a PostgreSQL port of the Sakila movie rental database—is loaded into the PostgreSQL instance to demonstrate real-world queries and administration in a secure, private cloud environment.

## What You'll Learn

- How to deploy a fully private PostgreSQL DB System on OCI using Terraform
- How to design a two-tier VCN with public and private subnets, security lists, and separate route tables
- How to provision a VM running `pgweb` for browser-based database access
- How to wire OCI credentials and passwords through Terraform state without a vault service

## Overview of OCI PostgreSQL

OCI PostgreSQL is Oracle's fully managed PostgreSQL database service. It runs standard PostgreSQL and is deployed into your VCN as a private endpoint — no public access is exposed. OCI handles patching, backups, and storage management.

### OCI PostgreSQL vs AWS RDS PostgreSQL

| **Aspect**            | **OCI PostgreSQL**                                        | **AWS RDS PostgreSQL**                              |
|-----------------------|-----------------------------------------------------------|-----------------------------------------------------|
| **Networking**        | Private subnet in VCN; no public endpoint                | Public or private subnet; public access configurable |
| **Shape model**       | Named shapes (PostgreSQL.VM.Standard.E5.Flex.2.32GB)     | Instance classes (db.t4g.micro, db.r6g.large, etc.) |
| **Read replicas**     | Not supported in this tier                               | Supported                                           |
| **Serverless option** | Not available                                            | Aurora Serverless v2                                |
| **Provisioning time** | 10–20 minutes                                            | 5–10 minutes                                        |
| **Backup**            | Automated backup with configurable retention             | Automated backup with geo-redundancy option         |

## Prerequisites

* [An OCI Account](https://cloud.oracle.com/)
* [Install OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
* [Install Latest Terraform](https://developer.hashicorp.com/terraform/install)
* OCI CLI configured: `~/.oci/config` with a valid DEFAULT profile

Set `OCI_COMPARTMENT_ID` to the OCID of the compartment you want to deploy into. If unset, the scripts fall back to the tenancy root.

## Download this Repository

```bash
git clone https://github.com/mamonaco1973/oci-postgres.git
cd oci-postgres
```

## Build the Code

Run [check_env](check_env.sh) then run [apply](apply.sh).

```bash
~/oci-postgres$ ./apply.sh
NOTE: Validating that required commands are found in your PATH.
NOTE: oci is found in the current PATH.
NOTE: terraform is found in the current PATH.
NOTE: jq is found in the current PATH.
NOTE: All required commands are available.
NOTE: Checking OCI CLI connection.
NOTE: Successfully connected to OCI.

Initializing the backend...
Initializing provider plugins...
- Reusing previous version of oracle/oci from the dependency lock file
- Using previously-installed oracle/oci v6.x.x

Terraform has been successfully initialized!
```

> **Note:** OCI PostgreSQL DB System provisioning typically takes **10–20 minutes**. The `./apply.sh` command will wait for pgweb to become reachable before printing the final summary.

## Build Results

After applying the Terraform configuration, the following OCI resources will be created:

### VCN & Subnets
- VCN: `postgres-vcn` — `10.0.0.0/23`
- Private subnet: `postgres-subnet` — `10.0.0.0/25` (PostgreSQL DB System, no public IPs)
- Public subnet: `vm-subnet` — `10.0.1.0/25` (pgweb VM, public IP assigned)

### Gateways & Route Tables
- Internet Gateway — routes public traffic to/from the VM subnet
- NAT Gateway — provides outbound-only internet access for the PostgreSQL subnet
- Route table per subnet wired to the appropriate gateway

### Security Lists
- `postgres-sl` — allows TCP 5432 inbound from the VM subnet only
- `postgres-vm-sl` — allows TCP 80 (HTTP) and TCP 22 (SSH) inbound from anywhere

### PostgreSQL DB System
- Shape: `PostgreSQL.VM.Standard.E5.Flex.2.32GB` (2 OCPUs, 32 GB RAM)
- PostgreSQL version: 14
- Private FQDN only — no public endpoint exposed
- Automated backups enabled
- Preloaded with the [Pagila sample database](https://github.com/devrimgunduz/pagila)

### pgweb VM
- Shape: `VM.Standard.E4.Flex` (1 OCPU, 4 GB RAM)
- Ubuntu 24.04 LTS
- Public IP — accessible at `http://<public-ip>`

## Credentials

After a successful apply, retrieve credentials with:

```bash
./get_password.sh
```

Output:
```
PostgreSQL DB System:
  Username : postgres
  Password : <generated>
  Host     : <fqdn> (private)

pgweb VM:
  Username : ubuntu
  Password : <generated>
  Public IP: <public-ip>
  URL      : http://<public-ip>
```

## pgweb Demo

[pgweb](https://github.com/sosedoff/pgweb) is a lightweight web-based PostgreSQL client. Navigate to `http://<public-ip>` and connect using the credentials from `./get_password.sh`.

| Field    | Value |
|----------|-------|
| Host     | PostgreSQL private FQDN |
| Port     | `5432` |
| Database | `pagila` |
| Username | `postgres` |
| Password | from `./get_password.sh` |

Query 1:
```sql
SELECT
    f.title AS film_title,
    CONCAT(a.first_name, ' ', a.last_name) AS actor_name
FROM
    pagila.film f
    JOIN pagila.film_actor fa ON f.film_id = fa.film_id
    JOIN pagila.actor a ON fa.actor_id = a.actor_id
ORDER BY
    f.title, actor_name
LIMIT 20;
```

Query 2:

```sql
SELECT
    f.title,
    STRING_AGG(
        CONCAT(a.first_name, ' ', a.last_name),
        ', ' ORDER BY a.last_name
    ) AS actor_names
FROM
    pagila.film f
    JOIN pagila.film_actor fa ON f.film_id = fa.film_id
    JOIN pagila.actor a ON fa.actor_id = a.actor_id
GROUP BY
    f.title
ORDER BY
    f.title
LIMIT 10;
```
