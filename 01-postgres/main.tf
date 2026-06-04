# ================================================================================
# Provider Configuration
# Auth is read from ~/.oci/config DEFAULT profile — no credentials in code
# ================================================================================

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "oci" {
  region = var.region
}

# ================================================================================
# SSH Key Pair
# Generated fresh each deploy — private key written to keys/ (gitignored).
# ECDSA P-256 is smaller and faster than RSA while being equally secure.
# ================================================================================

resource "tls_private_key" "ssh" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = "./keys/Private_Key"
  file_permission = "0600"
}

# ================================================================================
# Availability Domains
# OCI requires explicit AD selection — resolved dynamically so this works
# across regions with different AD counts.
# ================================================================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# ================================================================================
# Image Lookup
# Queries for the latest Ubuntu 24.04 image compatible with VM.Standard.E4.Flex.
# ================================================================================

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}
