[Reflection.Assembly]::LoadWithPartialName("Newtonsoft.Json")


$instance = "localhost"
$db = "WideWorldImporters"


$query = @"
WITH cte0
AS (
	SELECT cust.CustomerId
		,cust.DeliveryAddressLine1
		,cust.DeliveryAddressLine2
		,cust.DeliveryPostalCode
		,cust.PostalAddressLine1
		,cust.PostalAddressLine2
		,cust.PostalPostalCode
		,city1.CityName AS DeliveryCityName
		,sp1.StateProvinceCode AS DeliveryStateProvinceCode
		,sp1.SalesTerritory AS DeliverySalesTerritory
		,city2.CityName AS PostalCityName
		,sp2.StateProvinceCode AS PostalStateProvinceCode
		,sp2.SalesTerritory AS PostalSalesTerritory
	FROM Sales.Customers cust 
	JOIN Application.Cities city1 ON cust.DeliveryCityId = city1.CityId
	JOIN Application.StateProvinces sp1 ON city1.StateProvinceId = sp1.StateProvinceId
	JOIN Application.Cities city2 ON cust.PostalCityId = city2.CityId
	JOIN Application.StateProvinces sp2 ON city2.StateProvinceId = sp2.StateProvinceId
)

,cte1
AS (
	SELECT CustomerId
		,N'Delivery' AS AddressType
		,DeliveryAddressLine1 AS AddressLine1
		,DeliveryAddressLine2 AS AddressLine2
		,DeliveryPostalCode AS PostalCode
		,DeliveryCityName as CityName
		,DeliveryStateProvinceCode AS StateProvinceCode
		,DeliverySalesTerritory AS SalesTerritory
	FROM cte0

	UNION ALL

	SELECT CustomerId
		,N'Postal' AS AddressType
		,PostalAddressLine1 AS AddressLine1
		,PostalAddressLine2 AS AddressLine2
		,PostalPostalCode AS PostalCode
		,PostalCityName as CityName
		,PostalStateProvinceCode AS StateProvinceCode
		,PostalSalesTerritory AS SalesTerritory
	FROM cte0
)

SELECT CONVERT(nvarchar(36), NEWID()) AS id 
    ,o.OrderId % 400 AS partitionKey
    ,o.OrderId
	,o.SalespersonPersonId
	,o.PickedByPersonId
	,o.ContactPersonId
	,o.BackorderOrderId
	,o.OrderDate
	,o.ExpectedDeliveryDate
	,o.CustomerPurchaseOrderNumber
	,o.IsUndersupplyBackordered
	,o.Comments
	,o.DeliveryInstructions
	,o.InternalComments
	,o.PickingCompletedWhen
	,o.LastEditedBy
	,o.LastEditedWhen

	,cust.CustomerId AS [Customer.CustomerId]
	,cust.CustomerName AS [Customer.CustomerName]
	,cust.PhoneNumber AS [Customer.PhoneNumber]
	,cust.FaxNumber AS [Customer.FaxNumber]

	,(SELECT AddressType
			,AddressLine1
			,AddressLine2
			,CityName
			,StateProvinceCode
			,PostalCode
			,SalesTerritory
		FROM cte1
		WHERE CustomerId = cust.CustomerId
		FOR JSON PATH
		) AS [Customer.Addresses]
		
	,(SELECT l.OrderLineId 
			,l.Quantity
			,l.PickedQuantity
			,l.PickingCompletedWhen
			,l.LastEditedBy
			,l.LastEditedWhen
			,stock.StockItemId AS [StockItem.StockItemId]
			,stock.StockItemName AS [StockItem.StockItemName]
			,stock.Brand AS [StockItem.Brand]
			,stock.Size AS [StockItem.Size]
			,c.ColorName AS [StockItem.ColorName]
			,stock.UnitPrice AS [StockItem.UnitPrice]
			,stock.TaxRate AS [StockItem.TaxRate]
		FROM Sales.OrderLines l
		JOIN Warehouse.StockItems stock ON stock.StockItemId = l.StockItemId
		JOIN Warehouse.Colors c ON c.ColorId = stock.ColorId
		WHERE OrderId = o.OrderId 
		FOR JSON PATH
		) AS [OrderLines]
		,'Order' AS EntityType

FROM Sales.Orders o
JOIN Sales.Customers cust ON o.CustomerId = cust.CustomerId

ORDER BY OrderId

OFFSET {0} ROWS

FETCH NEXT {1} ROWS ONLY

FOR JSON PATH
"@



$query2 = @"
SELECT CONVERT(nvarchar(11), PersonId) AS id
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

from application.people
where personid = {0}
for json auto
/*, without_array_wrapper */
"@


$pageSize = 100
$pageNo = 0
$maxPages = 1

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
        $order.ToString() | Out-File -FilePath ("C:\\temp\\wwi\{0}.json" -f $order["id"].ToString())
    }

    $pageNo += 1;

    if (($orders.Count -lt $pageSize) -or ($pageNo -ge $maxPages))
    {
        break;
    }
}

