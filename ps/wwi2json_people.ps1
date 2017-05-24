[Reflection.Assembly]::LoadWithPartialName("Newtonsoft.Json")


$instance = "localhost"
$db = "WideWorldImporters"


$query = @"
SELECT CONVERT(nvarchar(36), NEWID()) AS id
    ,PersonId % 400 AS partitionKey
    ,PersonId
	,FullName
	,PreferredName
	,SearchName
	,IsPermittedToLogon
	,LogonName
	,IsExternalLogonProvider
	,IsSystemUser
	,IsEmployee
	,IsSalesperson
	,PhoneNumber
	,FaxNumber
	,EmailAddress
	,'Person' AS EntityType

FROM Application.People

ORDER BY PersonId

OFFSET {0} ROWS

FETCH NEXT {1} ROWS ONLY

FOR JSON AUTO

"@


$pageSize = 100
$pageNo = 0
$maxPages = 99999999

while ($true)
{
    $rowset = Invoke-Sqlcmd -ServerInstance $instance -Database $db -Query ($query -f ($pageNo * $pageSize), $pageSize) -MaxCharLength 32767

    #resulting json is broken across rows which is BAD mmm kay
    #so we concatenate them back into the complete json object
    $json = ""
    $rowset | ForEach-Object {$json += $_[0]}

    #now, parse into a json array
    $orders = [Newtonsoft.Json.Linq.JArray]::Parse($json)

    foreach ($order in $orders)
    {   
        $order.ToString() | Out-File -FilePath ("C:\\temp\\wwi2\{0}.json" -f $order["id"].ToString())
    }

    $pageNo += 1;

    if (($orders.Count -lt $pageSize) -or ($pageNo -ge $maxPages))
    {
        break;
    }
}

