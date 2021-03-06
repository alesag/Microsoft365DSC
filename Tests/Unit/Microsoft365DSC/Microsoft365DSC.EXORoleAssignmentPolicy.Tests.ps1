[CmdletBinding()]
param(
)
$M365DSCTestFolder = Join-Path -Path $PSScriptRoot `
                        -ChildPath "..\..\Unit" `
                        -Resolve
$CmdletModule = (Join-Path -Path $M365DSCTestFolder `
            -ChildPath "\Stubs\Microsoft365.psm1" `
            -Resolve)
$GenericStubPath = (Join-Path -Path $M365DSCTestFolder `
    -ChildPath "\Stubs\Generic.psm1" `
    -Resolve)
Import-Module -Name (Join-Path -Path $M365DSCTestFolder `
        -ChildPath "\UnitTestHelper.psm1" `
        -Resolve)

$Global:DscHelper = New-M365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource "EXORoleAssignmentPolicy" -GenericStubModule $GenericStubPath
Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        BeforeAll {
            $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
            $GlobalAdminAccount = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)

            Mock -CommandName Test-MSCloudLogin -MockWith {

            }

            Mock -CommandName Get-PSSession -MockWith {

            }

            Mock -CommandName Remove-PSSession -MockWith {

            }
        }

        # Test contexts
        Context -Name "Role Assignment Policy should exist. Role Assignment Policy is missing. Test should fail." -Fixture {
            BeforeAll {
                $testParams = @{
                    Name               = "Contoso Role Assignment Policy"
                    Description        = "This is the default Contoso Role Assignment Policy"
                    IsDefault          = $true
                    Roles              = "MyPersonalInformation", "MyDistributionGroupMembership"
                    Ensure             = 'Present'
                    GlobalAdminAccount = $GlobalAdminAccount
                }

                Mock -CommandName Get-RoleAssignmentPolicy -MockWith {
                    return @{
                        Name        = "Contoso Different Role Assignment Policy"
                        Description = "This is the default Contoso Role Assignment Policy"
                        IsDefault   = $true
                        Roles       = "MyPersonalInformation", "MyDistributionGroupMembership"
                    }
                }

                Mock -CommandName Set-RoleAssignmentPolicy -MockWith {
                    return @{
                        Name               = "Contoso Role Assignment Policy"
                        Description        = "This is the default Contoso Role Assignment Policy"
                        IsDefault          = $true
                        Roles              = "MyPersonalInformation", "MyDistributionGroupMembership"
                        Ensure             = 'Present'
                        GlobalAdminAccount = $GlobalAdminAccount
                    }
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }

            It "Should return Absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
            }
        }

        Context -Name "Role Assignment Policy should exist. Role Assignment Policy exists. Test should pass." -Fixture {
            BeforeAll {
                $testParams = @{
                    Name               = "Contoso Role Assignment Policy"
                    Description        = "This is the default Contoso Role Assignment Policy"
                    IsDefault          = $true
                    Roles              = "MyPersonalInformation", "MyDistributionGroupMembership"
                    Ensure             = 'Present'
                    GlobalAdminAccount = $GlobalAdminAccount
                }

                Mock -CommandName Get-RoleAssignmentPolicy -MockWith {
                    return @{
                        Name          = "Contoso Role Assignment Policy"
                        Description   = "This is the default Contoso Role Assignment Policy"
                        IsDefault     = $true
                        AssignedRoles = "MyPersonalInformation", "MyDistributionGroupMembership"
                    }
                }
            }

            It 'Should return true from the Test method' {
                Test-TargetResource @testParams | Should -Be $true
            }

            It 'Should return Present from the Get Method' {
                (Get-TargetResource @testParams).Ensure | Should -Be "Present"
            }
        }

        Context -Name "Role Assignment Policy should exist. Role Assignment Policy exists, Description mismatch. Test should fail." -Fixture {
            BeforeAll {
                $testParams = @{
                    Name               = "Contoso Role Assignment Policy"
                    Description        = "This is the default Contoso Role Assignment Policy"
                    IsDefault          = $true
                    Roles              = "MyPersonalInformation", "MyDistributionGroupMembership"
                    Ensure             = 'Present'
                    GlobalAdminAccount = $GlobalAdminAccount
                }

                Mock -CommandName Get-RoleAssignmentPolicy -MockWith {
                    return @{
                        Name          = "Contoso Role Assignment Policy"
                        Description   = "This is the different Contoso Role Assignment Policy"
                        IsDefault     = $true
                        AssignedRoles = "MyPersonalInformation", "MyDistributionGroupMembership"
                    }
                }

                Mock -CommandName Set-RoleAssignmentPolicy -MockWith {
                    return @{
                        Name               = "Contoso Role Assignment Policy"
                        Description        = "This is the default Contoso Role Assignment Policy"
                        IsDefault          = $true
                        Roles              = "MyPersonalInformation", "MyDistributionGroupMembership"
                        Ensure             = 'Present'
                        GlobalAdminAccount = $GlobalAdminAccount
                    }
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            BeforeAll {
                $testParams = @{
                    GlobalAdminAccount = $GlobalAdminAccount
                }

                $RoleAssignmentPolicy = @{
                    Name          = "Contoso Role Assignment Policy"
                    Description   = "This is the default Contoso Role Assignment Policy"
                    IsDefault     = $true
                    AssignedRoles = "MyPersonalInformation", "MyDistributionGroupMembership"
                }

                Mock -CommandName Get-RoleAssignmentPolicy -MockWith {
                    return $RoleAssignmentPolicy
                }
            }

            It "Should Reverse Engineer resource from the Export method when single" {
                $exported = Export-TargetResource @testParams
                ([regex]::Matches($exported, " EXORoleAssignmentPolicy " )).Count | Should -Be 1
                $exported.Contains("MyPersonalInformation") | Should -Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope

