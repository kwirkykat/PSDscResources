param 
(
    [Parameter(Mandatory = $true)]
    [String]
    $ConfigurationName
)
        

Configuration $ConfigurationName
{
    param 
    (        
        [String]
        $UserName = 'Test UserName',
        
        [String]
        $Description = 'Test Description',
        
        [String]
        $FullName = 'Test Full Name',
        
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',
        
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Password,

        [Boolean]
        $PasswordNeverExpires = $false
    )
    
    Import-DscResource -ModuleName 'PSDscResources'
    
    Node localhost {
        User UserResource1
        {
            UserName = $UserName
            Ensure = $Ensure
            FullName = $FullName
            Description = $Description
            Password = $Password
            PasswordNeverExpires = $PasswordNeverExpires
        }
    }
}
