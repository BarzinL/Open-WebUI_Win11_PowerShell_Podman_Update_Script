# Set variables
$containerName = "open-webui"
$newContainerName = "open-webui_new"
$imageName = "ghcr.io/open-webui/open-webui:latest"
$portMapping = "3000:8080"

# Function to check command status
function Check-CommandStatus {
    param (
        [int]$exitCode,
        [string]$command
    )
    if ($exitCode -ne 0) {
        Write-Host "Error: Command '$command' failed with exit code $($exitCode)." -ForegroundColor Red
        exit 1
    }
}

# Start script
Write-Host "Starting Open-WebUI update process..." -ForegroundColor Yellow

# Stop the existing container
Write-Host "Stopping the existing container '$containerName'..." -ForegroundColor Yellow
podman stop $containerName
$exitCode = $LASTEXITCODE
Check-CommandStatus -exitCode $exitCode -command "podman stop $containerName"

# Pull the new image
Write-Host "Pulling the latest image '$imageName'..." -ForegroundColor Yellow
podman pull $imageName
$exitCode = $LASTEXITCODE
Check-CommandStatus -exitCode $exitCode -command "podman pull $imageName"

# Create a new container with a new name
Write-Host "Creating a new container '$newContainerName'..." -ForegroundColor Yellow
podman create --name $newContainerName -p $portMapping -v ${containerName}:/app/backend/data $imageName
$exitCode = $LASTEXITCODE
Check-CommandStatus -exitCode $exitCode -command "podman create --name $newContainerName -p $portMapping -v ${containerName}:/app/backend/data $imageName"

# Start the new container
Write-Host "Starting the new container '$newContainerName'..." -ForegroundColor Yellow
podman start $newContainerName
$exitCode = $LASTEXITCODE
Check-CommandStatus -exitCode $exitCode -command "podman start $newContainerName"

# Verify the new container is running
Write-Host "Verifying the new container is running..." -ForegroundColor Yellow
$containerStatus = podman container inspect $newContainerName | ConvertFrom-Json | Select-Object -ExpandProperty State | Select-Object -ExpandProperty Status
if ($containerStatus -ne "running") {
    Write-Host "Error: The new container '$newContainerName' is not running. Status: '$containerStatus'" -ForegroundColor Red
    exit 1
}
Write-Host "New container '$newContainerName' is running." -ForegroundColor Green

# Remove the old container
Write-Host "Removing the old container '$containerName'..." -ForegroundColor Yellow
podman rm $containerName
$exitCode = $LASTEXITCODE
Check-CommandStatus -exitCode $exitCode -command "podman rm $containerName"

# Rename new container to old container name
Write-Host "Renaming the new container to '$containerName'..." -ForegroundColor Yellow
podman rename $newContainerName $containerName
$exitCode = $LASTEXITCODE
Check-CommandStatus -exitCode $exitCode -command "podman rename $newContainerName $containerName"

Write-Host "Update process completed successfully." -ForegroundColor Green
