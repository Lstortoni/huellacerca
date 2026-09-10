FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY global.json Directory.Build.props HuellaCerca.sln ./
COPY HuellaCerca.API/HuellaCerca.API.csproj HuellaCerca.API/
COPY HuellaCerca.MODEL/HuellaCerca.MODEL.csproj HuellaCerca.MODEL/
COPY HuellaCerca.CONTRACT/HuellaCerca.CONTRACT.csproj HuellaCerca.CONTRACT/
COPY HuellaCerca.INTERFACES/HuellaCerca.INTERFACES.csproj HuellaCerca.INTERFACES/
COPY HuellaCerca.SERVICES/HuellaCerca.SERVICES.csproj HuellaCerca.SERVICES/
COPY HuellaCerca.INFRASTRUCTURE/HuellaCerca.INFRASTRUCTURE.csproj HuellaCerca.INFRASTRUCTURE/
RUN dotnet restore HuellaCerca.sln
COPY . .
RUN dotnet publish HuellaCerca.API/HuellaCerca.API.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
COPY --from=build /app/publish .
USER app
ENTRYPOINT ["dotnet", "HuellaCerca.API.dll"]

