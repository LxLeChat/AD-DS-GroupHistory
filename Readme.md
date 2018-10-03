# Get-ADGroupHistory
Function to return the history of an AD DS Group.
The function is based on repadmin /showobjmeta. The function use a regex to parse the output of the repadmin /showobjmeta command. The result is formatted as an object.
Specify DC if you want repadmin to query a specific DC. If not specified, the function will find the closest DC from your location.


# Get-ADGroupHistory
Return the group history for Group1
```powershell
Get-ADGroupHistory -Name Group1 -DomainController DC01
```

