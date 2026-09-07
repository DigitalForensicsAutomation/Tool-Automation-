Add-Type -AssemblyName PresentationFramework, System.Windows.Forms

# 1. Define the WPF Graphical Interface Layout (XAML)
[xml]$XAML = @"
<Window xmlns="http://microsoft.com"
        xmlns:x="http://microsoft.com"
        Title="Air-Gapped Forensic Pipeline Automator (PA10 &amp; Axiom)" Height="580" Width="680" Background="#F4F4F4">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Target Forensic Workspaces -->
        <GroupBox Header=" Pipeline Workspace Configurations (Target High-Speed NVMe Drives) " Grid.Row="0" Margin="0,0,0,10" Padding="10" FontWeight="Bold">
            <Grid FontWeight="Normal">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="160"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="80"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="32"/>
                    <RowDefinition Height="32"/>
                    <RowDefinition Height="32"/>
                </Grid.RowDefinitions>
                
                <Label Content="Source Folder (.ufd):" Grid.Row="0" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="TxtSrc" Grid.Row="0" Grid.Column="1" Height="23" VerticalAlignment="Center"/>
                <Button Name="BtnBrowseSrc" Content="Browse" Grid.Row="0" Grid.Column="2" Height="23" Margin="5,0,0,0"/>
                
                <Label Content="PA10 NVMe Drive (E:\):" Grid.Row="1" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="TxtPaOut" Grid.Row="1" Grid.Column="1" Height="23" VerticalAlignment="Center"/>
                <Button Name="BtnBrowsePa" Content="Browse" Grid.Row="1" Grid.Column="2" Height="23" Margin="5,0,0,0"/>
                
                <Label Content="Axiom NVMe Drive (F:\):" Grid.Row="2" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="TxtAxOut" Grid.Row="2" Grid.Column="1" Height="23" VerticalAlignment="Center"/>
                <Button Name="BtnBrowseAx" Content="Browse" Grid.Row="2" Grid.Column="2" Height="23" Margin="5,0,0,0"/>
            </Grid>
        </GroupBox>

        <!-- Static Air-Gapped Executable Toolpaths -->
        <GroupBox Header=" Static Tool Executable Paths " Grid.Row="1" Margin="0,0,0,10" Padding="10" FontWeight="Bold">
            <Grid FontWeight="Normal">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="160"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="32"/>
                    <RowDefinition Height="32"/>
                </Grid.RowDefinitions>
                
                <Label Content="PA10 pas.exe Engine:" Grid.Row="0" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="TxtPaExe" Text="C:\Program Files\Cellebrite\Forensic\Inseyets Physical Analyzer\pas.exe" Grid.Row="0" Grid.Column="1" Height="23" VerticalAlignment="Center"/>
                
                <Label Content="Axiom Process Engine:" Grid.Row="1" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="TxtAxExe" Text="C:\Program Files\Magnet Forensics\Magnet AXIOM\Magnet AXIOM Process\AxiomProcess.exe" Grid.Row="1" Grid.Column="1" Height="23" VerticalAlignment="Center"/>
            </Grid>
        </GroupBox>

        <!-- Dynamic Real-Time Status Console -->
        <GroupBox Header=" Terminal Execution Log " Grid.Row="2" Margin="0,0,0,10" FontWeight="Bold">
            <TextBox Name="TxtLog" TextReadOnly="True" Background="#121212" Foreground="#00FF33" 
                     FontFamily="Consolas" FontSize="11" VerticalScrollBarVisibility="Auto" AcceptsReturn="True" FontWeight="Normal"/>
        </GroupBox>

        <!-- Control Action Panel -->
        <Grid Grid.Row="3">
            <Label Name="LblDiskStatus" Content="System Idle - Ready for pre-flight disk check" Foreground="#555555" VerticalAlignment="Center" HorizontalAlignment="Left"/>
            <Button Name="BtnLaunch" Content="🚀 Initialize Dual Pipeline" Height="35" HorizontalAlignment="Right" Width="200" FontWeight="Bold"/>
        </Grid>
    </Grid>
</Window>
"@

# 2. Compile and Initialize the WPF Windows Form Instance
$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Form = [Windows.Markup.XamlReader]::Load($Reader)

$TxtSrc = $Form.FindName("TxtSrc")
$TxtPaOut = $Form.FindName("TxtPaOut")
$TxtAxOut = $Form.FindName("TxtAxOut")
$TxtPaExe = $Form.FindName("TxtPaExe")
$TxtAxExe = $Form.FindName("TxtAxExe")
$TxtLog = $Form.FindName("TxtLog")
$BtnLaunch = $Form.FindName("BtnLaunch")
$LblDiskStatus = $Form.FindName("LblDiskStatus")

function Get-LocalFolder($Description) {
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = $Description
    if ($FolderBrowser.ShowDialog() -eq "OK") { return $FolderBrowser.SelectedPath }
    return ""
}

$Form.FindName("BtnBrowseSrc").Add_Click({ $TxtSrc.Text = Get-LocalFolder("Select Pristine Extraction Source Directory") })
$Form.FindName("BtnBrowsePa").Add_Click({ $TxtPaOut.Text = Get-LocalFolder("Select Dedicated Target NVMe Partition for PA10") })
$Form.FindName("BtnBrowseAx").Add_Click({ $TxtAxOut.Text = Get-LocalFolder("Select Dedicated Target NVMe Partition for Magnet Axiom") })

function Write-PipelineConsole($Message) {
    $Form.Dispatcher.Invoke([Action]{
        $TxtLog.AppendText("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $Message`r`n")
        $TxtLog.ScrollToEnd()
    })
}

# 3. Asynchronous Pipeline Logic Hook
$BtnLaunch.Add_Click({
    if ([string]::IsNullOrWhiteSpace($TxtSrc.Text) -or [string]::IsNullOrWhiteSpace($TxtPaOut.Text) -or [string]::IsNullOrWhiteSpace($TxtAxOut.Text)) {
        [System.Windows.MessageBox]::Show("Configuration Error: All target workstation paths must be specified.", "Path Validation Error", "OK", "Error")
        return
    }

    $BtnLaunch.IsEnabled = $false
    Write-PipelineConsole "[+] Pre-flight verification initiated. Processing drive matrix configurations..."

    Start-Job -ScriptBlock {
        param($Src, $PaOut, $AxOut, $PaExe, $AxExe)
        
        function Send-Msg($Str) { $Str }
        $LogFile = Join-Path $Src "ForensicPipeline_RunLog.txt"
        function Write-ToLocalLog($Text) {
            "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $Text" | Out-File -FilePath $LogFile -Append -Encoding utf8
        }

        if (-not (Test-Path $PaExe) -or -not (Test-Path $AxExe)) {
            Send-Msg "[!] CRITICAL ERROR: Forensic engine executables not found. Verify software installations."
            return
        }

        # Offline Disk Capacity Check Rule (Requires minimum 500GB free space)
        $PaDrive = Split-Path -Qualifier $PaOut
        $AxDrive = Split-Path -Qualifier $AxOut
        $PaDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$PaDrive'"
        $AxDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$AxDrive'"
        $MinSpaceBytes = 500GB
        
        if ($PaDisk.FreeSpace -lt $MinSpaceBytes -or $AxDisk.FreeSpace -lt $MinSpaceBytes) {
            Send-Msg "[!] CRITICAL CAPACITY ERROR: Target drive space insufficient. Minimum 500 GB required."
            return
        }

        $UfdFiles = Get-ChildItem -Path $Src -Filter "*.ufd"
        if ($UfdFiles.Count -eq 0) {
            Send-Msg "[!] Pipeline halted: Zero (.ufd) metadata collections found."
            return
        }

        Send-Msg "[+] Workstation space confirmed. Launching parallel loops for $($UfdFiles.Count) mobile cases."

        foreach ($File in $UfdFiles) {
            $CaseName = $File.BaseName
            Send-Msg ">>> Spawning Dual Processing Nodes for Case File: $CaseName <<<"

            $PaWorkDir = Join-Path $PaOut "$($CaseName)_PA10_Run"
            $AxWorkDir = Join-Path $AxOut "$($CaseName)_AXIOM_Run"
            $null = New-Item -ItemType Directory -Path $PaWorkDir -Force
            $null = New-Item -ItemType Directory -Path $AxWorkDir -Force

            $BinPath = $File.FullName.ToLower().Replace(".ufd", ".bin")
            if (-not (Test-Path $BinPath)) { $BinPath = $File.FullName.ToLower().Replace(".ufd", ".tar") }

            Send-Msg "[->] Duplicating forensic collection data arrays to separate NVMe processing units..."
            Copy-Item -Path $File.FullName -Destination (Join-Path $PaWorkDir $File.Name) -Force
            Copy-Item -Path $File.FullName -Destination (Join-Path $AxWorkDir $File.Name) -Force

            if (Test-Path $BinPath) {
                $BinName = Split-Path $BinPath -Leaf
                Copy-Item -Path $BinPath -Destination (Join-Path $PaWorkDir $BinName) -Force
                Copy-Item -Path $BinPath -Destination (Join-Path $AxWorkDir $BinName) -Force
            }

            $PaTargetFile = Join-Path $PaWorkDir $File.Name
            $AxTargetFile = Join-Path $AxWorkDir $File.Name
            $PaOutputTarget = Join-Path $PaWorkDir "PA10_Decoded_Case"
            $AxOutputTarget = Join-Path $AxWorkDir "Axiom_Decoded_Case"

            Send-Msg "[⚡] Detaching headless engine instances into parallel processing channels..."

            $ProcPA = Start-Process -FilePath $PaExe -ArgumentList "-open `"$PaTargetFile`" -method Forensic -project `"$PaOutputTarget`" -examine" -NoNewWindow -PassThru
            $ProcAX = Start-Process -FilePath $AxExe -ArgumentList "/v `"Mobile`" /i `"$AxTargetFile`" /o `"$AxOutputTarget`" /g" -NoNewWindow -PassThru

            while (-not $ProcPA.HasExited -or -not $ProcAX.HasExited) {
