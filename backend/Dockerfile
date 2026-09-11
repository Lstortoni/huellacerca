FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY global.json Directory.Build.props HuellaCerca.sln ./
COPY HuellaCerca.API/HuellaCerca.API.csproj HuellaCerca.API/
COPY HuellaCerca.MODEL/HuellaCerca.MODEL.csproj HuellaCerca.MODEL/
COPY HuellaCerca.CONTRACT/HuellaCerca.CONTRACT.csproj HuellaCerca.CONTRACT/
COPY HuellaCerca.INTERFACES/HuellaCerca.INTERFACES.csproj HuellaCerca.INTERFACES/
COPY HuellaCerca.SERVICES/HuellaCerca.SERVICES.csproj HuellaCerca.SERVICES/
COPY HuellaCerca.INFRASTRUCTURE/HuellaCerca.INFRASTRUCTURE.csproj HuellaCerca.INFRASTRUCTURE/
COPY HuellaCerca.GeoRefImporter/HuellaCerca.GeoRefImporter.csproj HuellaCerca.GeoRefImporter/
RUN dotnet restore HuellaCerca.sln
RUN dotnet restore HuellaCerca.GeoRefImporter/HuellaCerca.GeoRefImporter.csproj
COPY . .

FROM build AS tools
RUN dotnet tool install --tool-path /tools dotnet-ef --version 8.0.22
ENV PATH="/tools:${PATH}"

FROM build AS publish
RUN dotnet publish HuellaCerca.API/HuellaCerca.API.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false
RUN dotnet publish HuellaCerca.GeoRefImporter/HuellaCerca.GeoRefImporter.csproj -c Release -o /app/importer --no-restore /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/runtime:8.0 AS importer
WORKDIR /app
COPY --from=publish /app/importer .
USER app
ENTRYPOINT ["dotnet", "HuellaCerca.GeoRefImporter.dll"]

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
COPY --from=publish /app/publish .
USER app
ENTRYPOINT ["dotnet", "HuellaCerca.API.dll"]
