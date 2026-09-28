FROM mcr.microsoft.com/powershell:7.5-ubuntu-24.04

RUN pwsh -NoLogo -NoProfile -NonInteractive -Command \
    '$ErrorActionPreference = "Stop"; \
     Install-Module Az.Accounts -Repository PSGallery -Scope AllUsers -Force -AllowClobber; \
     Install-Module SqlServer -Repository PSGallery -Scope AllUsers -Force -AllowClobber'

COPY scripts/ /opt/amiasea/scripts/