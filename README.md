# image-utility

# Amiasea Utility Image

Reusable Amiasea utility image for Azure-based imperative operations.

The image provides PowerShell and Azure/SQL tooling used by Amiasea execution workloads.

## Included

* PowerShell 7
* Az.Accounts PowerShell module
* SqlServer PowerShell module
* Amiasea utility scripts

## Image

The published image is available from GitHub Container Registry:

`ghcr.io/amiasea/image-utility`

## Base Image

The image is based on:

`mcr.microsoft.com/powershell:7.5-ubuntu-24.04`

## Purpose

This image provides a reusable execution environment for Amiasea operations that require Azure authentication or SQL Server access.

The image itself does not establish Azure infrastructure, assign identities, or determine when an operation executes.

Those concerns belong to the workload that invokes the utility.

## Local Build

```bash
docker build -t amiasea/image-utility:local .
```
