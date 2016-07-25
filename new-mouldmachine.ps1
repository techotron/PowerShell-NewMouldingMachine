import-module remotedesktop, activedirectory

# =============================================== New-MouldingMachine Function ==============================================================================

$groupMembership = @("Production Workflow System Users", "RDS_pirana-users", "RDS_sharepoint-users")

function new-mouldingMachine {

    param(
        [string]$name,
        [switch]$configureRDS
    )

    # Test if AD account exists
    try {
    
        $a = get-aduser -Identity $name
        write-warning "An account for $name already exists in AD!"
        
    } catch {

        if (!($configureRDS)) {

            # Just create the user - DO NOT PUBLISH RDS APP

            write-host "Creating new AD account for $name"

            New-aduser $name.ToUpper() `
            -givenname $name.ToUpper() `
            -displayname $name.ToUpper() `
            -description "Production Workflow System" `
            -city "Manchester" `
            -postalcode "M22 4TY" `
            -UserPrincipalName  "$name@hellermanntytongroup.com" `
            -Company "HellermannTyton" `
            -Department "Production Workflow System" `
            -Enabled:$true `
            -Path "OU=Production Workflow System,OU=Manchester,OU=Sites,OU=HT,DC=Hellermanntytongroup,DC=com" `
            -PasswordNeverExpires:$true `
            -AccountPassword (convertto-securestring -asplaintext "Password01" -force)

            # Add new user to standard groups
            foreach ($grp in $groupMembership) {

                Add-ADGroupMember -Identity $grp -Members $name

            }

        }

        if ($configureRDS) {

            # Create the user in AD and publish app in RDS

            write-host "Creating new AD account for $name and publishing a new Remote App in RDS"

            New-aduser $name.ToUpper() `
            -givenname $name.ToUpper() `
            -displayname $name.ToUpper() `
            -description "Production Workflow System" `
            -city "Manchester" `
            -postalcode "M22 4TY" `
            -UserPrincipalName  "$name@hellermanntytongroup.com" `
            -Company "HellermannTyton" `
            -Department "Production Workflow System" `
            -Enabled:$true `
            -Path "OU=Production Workflow System,OU=Manchester,OU=Sites,OU=HT,DC=Hellermanntytongroup,DC=com" `
            -PasswordNeverExpires:$true `
            -AccountPassword (convertto-securestring -asplaintext "Password01" -force)

            # Add new user to standard groups
            foreach ($grp in $groupMembership) {

                Add-ADGroupMember -Identity $grp -Members $name

            }
        
            $url = "http://sps-serv:8001/PMSAddinWeb/MachineControlPanel?SPHostUrl=http%3A%2F%2Fsps-serv%2Fsites%2FPMS%2F&SPLanguage=en-US&SPClientTag=0&SPProductNumber=15.0.4763.1000&machineName=$name"
            new-rdremoteapp -Alias "z_$name" -DisplayName "z_$name" -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ShowInWebAccess $true -collectionname "remote apps" -ConnectionBroker "rds-gw-serv-2.hellermanntytongroup.com" -usergroups "UKGROUP\$name" -commandlinesetting require -requiredcommandline $url

            }

    }

}


# =============================================== Remove-MouldingMachine Function ===========================================================================

function remove-mouldingMachine {

    param(
        [string]$name,
        [switch]$removeRDS
    )

        # Test if AD account exists
    try {
    
        $sam = (get-aduser -Identity $name).samaccountname

        if (!($removeRDS)) {

            write-host "Removing AD account: $sam"
            Remove-ADUser -Identity $sam -Confirm:$false

        }

        if ($removeRDS) {

            write-host "Removing AD account: $sam and published app: z_$sam"
            Remove-ADUser -Identity $sam -Confirm:$false
            Remove-RDRemoteApp -CollectionName "remote apps" -ConnectionBroker "rds-gw-serv-2.hellermanntytongroup.com" -Alias "z_$sam" -Confirm:$false -force

        }

        
    } catch {

        write-warning "An account for $name wasn't found in AD!"

    }
}
