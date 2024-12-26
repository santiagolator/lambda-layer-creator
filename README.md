# Lambda Layer Creator

This PowerShell script creates AWS Lambda layers using Docker or Podman. It supports both Python and Node.js runtimes and allows for package installation either from a list of packages or from a requirements file.

## Features

- Supports both Python and Node.js Lambda runtimes
- Uses Docker or Podman for consistent build environments
- Can install packages from a list or a requirements file (requirements.txt for Python, package.json for Node.js)
- Option to create only the ZIP file without uploading to AWS
- Flexible container engine selection (Docker or Podman)

## Prerequisites

- PowerShell 5.1 or later
- Docker or Podman installed and configured
- AWS CLI installed and configured (if uploading to AWS)

## Usage

```powershell
powershell .\create-layer.ps1 -layername <string> -runtime <string> [-packages <string[]>] [-requirementsFile <string>] [-zipOnly] [-containerEngine <string>]
```

### Parameters

- `layername`: The name of the Lambda layer to create.
- `runtime`: The AWS Lambda runtime to use (e.g., python3.12, nodejs14.x).
- `packages`: List of packages to install (use this or `requirementsFile`).
- `requirementsFile`: Path to the requirements file (requirements.txt for Python, package.json for Node.js).
- `zipOnly`: If specified, only creates the ZIP file without uploading to AWS.
- `containerEngine`: Container engine to use: "docker" or "podman" (default).

## Examples

1. Create a Python layer with specific packages:

```powershell
powershell .\create-layer.ps1 -layername "my-python-layer" -runtime "python3.12" -packages "fastapi","mangum","python-jose" -zipOnly
```

2. Create a Node.js layer using a package.json file with Podman:
   
```powershell
powershell .\create-layer.ps1 -layername "my-node-layer" -runtime "nodejs14.x" -requirementsFile "path/to/package.json" -containerEngine podman
```

3. Create and upload a Python layer to AWS using a requirements.txt file:
```powershell
powershell .\create-layer.ps1 -layername "my-aws-layer" -runtime "python3.11" -requirementsFile "path/to/requirements.txt"
```

## Notes

- Ensure you have the necessary permissions to create and upload Lambda layers if using the AWS upload feature.
- The script uses the official AWS SAM build images for consistent environments.
- For Python layers, `__pycache__` directories are excluded from the final ZIP file.

## Contributing

Contributions to improve the script are welcome. Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)
