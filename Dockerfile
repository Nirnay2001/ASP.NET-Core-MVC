FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /app

COPY . .

EXPOSE 9090

RUN dotnet restore
RUN dotnet publish -c Release -o out
RUN dotnet run


