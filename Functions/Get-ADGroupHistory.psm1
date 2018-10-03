
Function Get-ADGroupHistory {
	<#
    .SYNOPSIS
    Permet de retourner la dernier du dernier ajout/suppression d'un membre d'un groupe.
	Se base sur la commande REPADMIN
	Requiert le module ActiveDirectory

    .DESCRIPTION
    Permet de retourner la dernier du dernier ajout/suppression d'un membre d'un groupe
	Accepte le wildcard *, voir exemples

    .EXAMPLE
    Get-GroupHistory -name <groupe>

    .EXAMPLE
    Get-GroupHistory -Name "domain ad*" | where {(New-TimeSpan -Start ($_.date) -End (get-date)).Days -le 1}

    .EXAMPLE
    Get-GroupHistory -name <groupe> -DomainController <DC>
	
	.EXAMPLE
    Get-GroupHistory -name <groupe*> -DomainController <DC>

    .EXAMPLE
	"<groupe1>","<groupe2>" | Get-GroupHistory
	
	.EXAMPLE
	"<groupe*>","<groupe2>" | Get-GroupHistory
	
    .PARAMETER Name
    Nom de groupe entier ou partiel
    Attention aux wildcard, cela peut
	
	.PARAMETER DomainController
    Non requis.
    Cherchera le DC le plus proche.
    Nom d'un domaine controleur ou la commande lancera sa requete.

    #>
    [cmdletbinding()]
	param(
        [ValidateScript({If(Get-ADGroup -Filter "name -like '$_'"){$true}else{$false}})]
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ValueFromPipeline=$True)]
		[string[]]$Name,
        [ValidateScript({If(Get-ADDomainController -Filter "name -eq '$_'"){$true}else{$false}})]
		[Parameter(Mandatory=$false)]
		[string]$DomainController
		)

	Begin
    {}
	
	Process
    {
        
        If ( !$DomainController )
        {
            Write-Verbose "DomainController parameter was not specified... getting closest DC Name..."
            $DomainController = (Get-ADDomainController -Discover -NextClosestSite).name
            Write-Verbose "Closest DC Name is: $DomainController..."
        
        }
        Write-Verbose "Getting list of group(s)..."

        [array]$GroupsList = Get-ADGroup -Filter "name -like '$($name[0])'" | Select-Object name,distinguishedname

        Foreach ( $Group in $GroupsList )
        {

            Write-Verbose "Launching Repadmin command for group: $($group.name)..."
            Write-Verbose "Running the following command: repadmin /showobjmeta $DomainController $($Group.Distinguishedname)"
            
            $RepAdminResult = repadmin /showobjmeta $DomainController $Group.Distinguishedname | select-string " member " -context 0,2

            If ( !$? )
            {
                Write-Verbose "Repadmin command did not run successfully..."
                Throw "Repadmin command did not run successfully..."
            }
            Else
            {
        
                Write-Verbose "Repadmin command did run successfully..."

            }

            Write-Verbose "Analyzing and Formating results for group: $($group.name)..."

            Foreach ( $line in $RepAdminResult )
            {

                $a = $line
                $b = $a.Line -replace "(\s+)",","
                $TmpSplit = $b.split(",")
                $c = $a.Context.PostContext[1] -replace "^\s+",""
                $d = Try { Get-ADObject $c -ErrorAction Stop } Catch { @{Name="";ObjectClass=""}}

                $properties = [Ordered]@{
                    Name       = $Group.Name
                    Action     = switch -wildcard ($TmpSplit[0]) { "A*" {"Removed"} "P*" {"Added"} }
                    Date       = get-date "$($TmpSplit[2]) $($TmpSplit[3])"
                    SourceDc   = ($TmpSplit[4].split("\"))[1]
                    SourceSite = ($TmpSplit[4].split("\"))[0]
                    ObjectName = $d.Name
                    ObjectType = $d.ObjectClass
                    ObjectDN   = $c
                }

                New-Object -TypeName PsObject -Property $properties
                Remove-Variable a, c, d, tmpsplit, properties

            }

            Remove-Variable RepAdminResult

        }
    
    }

    End
    {}
}