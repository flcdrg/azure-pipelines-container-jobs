# Node 16, .NET 6 and PowerShell 7

FROM node:16-alpine3.16

# From https://github.com/dotnet/dotnet-docker/blob/7d0baecabac1f42b65e12a3bdaa0aa291a406d50/src/sdk/6.0/alpine3.16/amd64/Dockerfile#L4
ENV \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    # Unset ASPNETCORE_URLS from aspnet base image
    ASPNETCORE_URLS= \
    # Do not generate certificate
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # SDK version
    DOTNET_SDK_VERSION=6.0.302 \
    # Disable the invariant mode (set in base image)
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetSDK-Alpine-3.16 \
    DOTNET_ROOT=/usr/share/dotnet

ARG powershell_version=7.2.5
RUN apk add --no-cache --virtual .pipeline-deps readline linux-pam \
  && apk --no-cache add bash sudo shadow \
  && apk del .pipeline-deps \
  # .NET prerequisites
  && apk add --no-cache icu-libs krb5-libs libgcc libintl libssl1.1 libstdc++ zlib \
  && apk add --no-cache libgdiplus --repository https://dl-3.alpinelinux.org/alpine/edge/testing/ \
  # PowerShell
  && apk add --no-cache \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    tzdata \
    userspace-rcu \
    curl \
  && curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin -Channel 6.0 -InstallDir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
  && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust \
  # Download the powershell '.tar.gz' archive
  && curl -L https://github.com/PowerShell/PowerShell/releases/download/v${powershell_version}/powershell-${powershell_version}-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz \
  # Create the target folder where powershell will be placed
  && mkdir -p /opt/microsoft/powershell/7 \
  # Expand powershell to the target folder
  && tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
  # Set execute permissions
  && chmod +x /opt/microsoft/powershell/7/pwsh \
  # Create the symbolic link that points to pwsh
  && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh \
  && pwsh --version

LABEL "com.azure.dev.pipelines.agent.handler.node.path"="/usr/local/bin/node"

# This label allows the image to be linked back to the repository
LABEL org.opencontainers.image.source https://github.com/flcdrg/azure-pipelines-container-jobs

CMD [ "node" ]