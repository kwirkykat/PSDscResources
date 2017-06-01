<#
    To run these tests, the currently logged on user must have rights to create a user.
    These integration tests cover creating a brand new user, updating values 
    of a user that already exists, and deleting a user that exists.
#> 

# Suppressing this rule since we need to create a plaintext password to test this resource
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

if ($PSVersionTable.PSVersion.Major -lt 5 -or $PSVersionTable.PSVersion.Minor -lt 1)
{
    Write-Warning -Message 'Cannot run PSDscResources integration tests on PowerShell versions lower than 5.1'
    return
}

$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

$script:testFolderPath = Split-Path -Path $PSScriptRoot -Parent
$script:testHelpersPath = Join-Path -Path $script:testFolderPath -ChildPath 'TestHelpers'
Import-Module -Name (Join-Path -Path $script:testHelpersPath -ChildPath 'CommonTestHelper.psm1')

$script:testEnvironment = Enter-DscResourceTestEnvironment `
    -DscResourceModuleName 'PSDscResources' `
    -DscResourceName 'MSFT_UserResource' `
    -TestType 'Integration'

try
{

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath 'MSFT_UserResource.config.ps1'

    Describe 'User Integration Tests' {
        BeforeAll {
            $VerbosePreference = 'Continue'
            Write-Verbose -Message '----------START USER TESTS----------'

            $script:configData = @{
            AllNodes = @(
                    @{
                        NodeName = 'localhost'
                        PSDscAllowPlainTextPassword = $true
                    }
                )
            }

            $script:testUserName = 'TestUserName12345'
            $script:testPassword = 'StrongOne7.'
            $script:testDescription = 'Test Description'
            $script:newTestDescription = 'New Test Description'
            $script:secureTestPassword = ConvertTo-SecureString $script:testPassword -AsPlainText -Force
            $script:testCredential = New-Object PSCredential ($script:testUserName, $script:secureTestPassword) 
        }

        BeforeEach {
            $user = Get-LocalUser -Name $script:testUserName -ErrorAction 'SilentlyContinue'

            if ($null -ne $user)
            {
                Write-Verbose -Message "User with name $script:testUserName exists with description $($user.Description)"
            }
            else
            {
                Write-Verbose -Message "User with name $script:testUserName does not exist"
            }

            ipconfig /renew
        }

        AfterAll {
            Write-Verbose -Message '----------END USER TESTS----------'
            $VerbosePreference = 'SilentlyContinue'
        }

        Context 'Should create a new user' {
            $configurationName = 'MSFT_User_NewUser'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $userParameters = @{
                UserName = $script:testUserName
                Password = $script:testCredential
                Description = $script:testDescription
                Ensure = 'Present'
            }

            It 'Should compile and run configuration' {
                {
                    . $configFile -ConfigurationName $configurationName
                    & $configurationName @userParameters -OutputPath $configurationPath -ConfigurationData $script:configData -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -Wait -Force
                } | Should Not Throw
            }
                
            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $null = Get-DscConfiguration -ErrorAction 'Stop' } | Should Not Throw
            }
                
            It 'Should return the correct configuration' {
                $currentConfig = Get-DscConfiguration
                $currentConfig.UserName | Should Be $userParameters.UserName
                $currentConfig.Ensure | Should Be $userParameters.Ensure
                $currentConfig.Description | Should Be $userParameters.Description
                $currentConfig.PasswordNeverExpires | Should Be $false
                $currentConfig.Disabled | Should Be $false
                $currentConfig.PasswordChangeRequired | Should Be $null
            }
        }
        
        Context 'Should update Description of an existing user' {
            $configurationName = 'MSFT_User_UpdateUserDescription'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $userParameters = @{
                UserName = $script:testUserName
                Password = $script:testCredential
                Description = 'New Test Description'
                Ensure = 'Present'
            }

            It 'Should compile and run configuration' {
                {
                    . $configFile -ConfigurationName $configurationName
                    & $configurationName @userParameters -OutputPath $configurationPath -ConfigurationData $script:configData -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -Wait -Force
                } | Should Not Throw
            }
                
            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $null = Get-DscConfiguration -ErrorAction 'Stop' } | Should Not Throw
            }
                
            It 'Should return the correct configuration' {
                $currentConfig = Get-DscConfiguration
                $currentConfig.UserName | Should Be $userParameters.UserName
                $currentConfig.Ensure | Should Be $userParameters.Ensure
                $currentConfig.Description | Should Be $userParameters.Description
                $currentConfig.PasswordNeverExpires | Should Be $false
                $currentConfig.Disabled | Should Be $false
                $currentConfig.PasswordChangeRequired | Should Be $null
            }
        }

        Context 'Should update Description, FullName, and PasswordNeverExpires properties of an existing user' {
            $configurationName = 'MSFT_User_UpdateUserPassword'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $userParameters = @{
                UserName = $script:testUserName
                Password = $script:testCredential
                Description = $script:testDescription
                FullName = 'New Full Name'
                PasswordNeverExpires = $true
                Ensure = 'Present'
            }

            It 'Should compile and run configuration' {
                {
                    . $configFile -ConfigurationName $configurationName
                    & $configurationName @userParameters -OutputPath $configurationPath -ConfigurationData $script:configData -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -Wait -Force
                } | Should Not Throw
            }
                
            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $null = Get-DscConfiguration -ErrorAction 'Stop' } | Should Not Throw
            }
                
            It 'Should return the correct configuration' {
                $currentConfig = Get-DscConfiguration
                $currentConfig.UserName | Should Be $userParameters.UserName
                $currentConfig.Ensure | Should Be $userParameters.Ensure
                $currentConfig.Description | Should Be $userParameters.Description
                $currentConfig.PasswordNeverExpires | Should Be $userParameters.PasswordNeverExpires
                $currentConfig.Disabled | Should Be $false
                $currentConfig.FullName | Should Be $userParameters.FullName
                $currentConfig.PasswordChangeRequired | Should Be $null
            }
        }
        
        Context 'Should delete an existing user' {
            $configurationName = 'MSFT_User_NewUser'
            $configurationPath = Join-Path -Path $TestDrive -ChildPath $configurationName

            $userParameters = @{
                UserName = $script:testUserName
                Password = $script:testCredential
                Ensure = 'Absent'
            }

            It 'Should compile and run configuration' {
                {
                    . $configFile -ConfigurationName $configurationName
                    & $configurationName @userParameters -OutputPath $configurationPath -ConfigurationData $script:configData -ErrorAction 'Stop'
                    Start-DscConfiguration -Path $configurationPath -Wait -Force
                } | Should Not Throw
            }
                
            It 'Should be able to call Get-DscConfiguration without throwing' {
                { $null = Get-DscConfiguration -ErrorAction 'Stop' } | Should Not Throw
            }
                
            It 'Should return the correct configuration' {
                $currentConfig = Get-DscConfiguration
                $currentConfig.UserName | Should Be $userParameters.UserName
                $currentConfig.Ensure | Should Be $userParameters.Ensure
            }
        }
    }
}
finally
{
    Exit-DscResourceTestEnvironment -TestEnvironment $script:testEnvironment
}
