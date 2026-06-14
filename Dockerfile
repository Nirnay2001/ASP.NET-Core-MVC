FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app
COPY . .
EXPOSE 80
RUN dotnet restore
RUN dotnet publish -c Release -o out
RUN dotnet run 
ENTRYPOINT ["dotnet", "MVC Application.dll"]
