# Jpg file size reduction settings.
$Location = "X:\"
$FilesOverXinBytes = 1048576
$JpegQualityPercentage = 100
$MaxDimension1 = 1920
$MaxDimension2 = 1080

# Make sure $MaxDimension1 has the largest variable.
If ($MaxDimension1 -lt $MaxDimension2)
{
    $MaxTemp = $MaxDimension2
    $MaxDimension2 = $MaxDimension1
    $MaxDimension1 = $MaxTemp
    Clear-Variable MaxTemp
}

# If there is no trailing backslash for $Location, add the backslash.
If (!($Location.Substring($Location.Length-1) -eq "\"))
{
    $Location = "$Location\"
}

# Scan for all jpg files in location over the size defined to attempt to reduce in size.
$ListOfFiles = Get-ChildItem "$Location*" -Recurse -Force -include @("*.jpg","*.jpeg")| Where {!$_.PsIsContainer}| where-object {$_.length -gt $FilesOverXinBytes}

ForEach ($File in $ListOfFiles)
{
    Write-Host "Processing $File`."
    # Get original time stamps.
    $CreationTime = $File.CreationTime
    $LastWriteTime = $File.LastWriteTime
    $LastAccessTime = $File.LastAccessTime

    # Enable the creation of images.
    Add-Type -AssemblyName System.Drawing

    # Get source image from source file.
    $SourceImage = [System.Drawing.Image]::FromFile($File.FullName)

    # Find original file dimensions.
    If ($SourceImage.Width -gt $SourceImage.Height)
    {
        $LowestNumber = $SourceImage.Height
        $HighestNumber = $SourceImage.Width
    }
    Else
    {
        $LowestNumber = $SourceImage.Width
        $HightNumber = $SourceImage.Height
    }
    
    # If the boundery is bigger than the Max Dimensions, find a size in the same ratio format that the image will fit into.
    If ($LowestNumber -ge $MaxDimension2)
    {
        $SizeChange = $LowestNumber / $MaxDimension2
        $Horizontal = [Int]($SourceImage.Width / $SizeChange)
        $Vertical = [Int]($SourceImage.Height / $SizeChange)
    }
    ElseIf ($HighestNumber -ge $MaxDimension1)
    {
        $SizeChange = $HighestNumber / $MaxDimension1
        $Horizontal = [Int]($SourceImage.Width / $SizeChange)
        $Vertical = [Int]($SourceImage.Height / $SizeChange)
    }
    Else
    {
        $Horizontal = $SourceImage.Width
        $Vertical = $SourceImage.Height
    }

    # In case you want to lower the quality of the image to save space, set the Codec compression percentage.
    $QualitySetting = [System.Drawing.Imaging.Encoder]::Quality
    $EncoderParameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $EncoderParameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($QualitySetting, $JpegQualityPercentage)
    $JpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|Where {$_.MimeType -eq 'Image/Jpeg'}

    # Create a new bitmap at the new resolution to construct an image.
    $Bitmap = New-Object System.Drawing.Bitmap($Horizontal,$Vertical)

    # Create image for editing.
    $Image = [System.Drawing.Graphics]::FromImage($Bitmap)

    # Ensure the image is clear.
    $Image.Clear([System.Drawing.Color]::FromArgb(255,255,255,255))

    # Draw image.
    $Image.DrawImage($SourceImage,0,0, $Horizontal, $Vertical)

    # Close file so it can be overwritten.
    $SourceImage.Dispose()

    # Save edited bitmap to file.
    $Bitmap.Save($File.FullName,$JpegCodec,$($EncoderParameters))

    # Clean up and remove objects.
    $Bitmap.Dispose()
    $Image.Dispose()
    $SourceDestinationFile

    # Reset to original time stamps.
    $File.CreationTime = $CreationTime
    $File.LastWriteTime = $LastWriteTime
    $File.LastAccessTime = $LastAccessTime
}