BeforeAll {
  $Script:ManifestPath = $PSCommandPath.Replace('.tests/', '').Replace('.Tests.ps1', '.psd1')
}

Describe 'Manifest' {
  BeforeAll {
    [PSModuleInfo]$Script:Module = $null
  }

  It 'Valid' {
    $Script:Module = Test-ModuleManifest -Path $ManifestPath
    $Module | Should -Not -BeNullOrEmpty
  }

  It 'Version' {
    $Version = $Module.Version.ToString()
    $Module.ReleaseNotes | Should -BeLike "*$Version"
  }

  It 'Commands' {
    $Module.ExportedFunctions | Should -Not -BeNullOrEmpty
    $Module.ExportedCommands | Should -Not -BeNullOrEmpty
  }
}

Describe 'Module' {
  It 'Import' {
    Import-Module -Name $ManifestPath -Force -PassThru | Should -Not -BeNullOrEmpty
  }
}
