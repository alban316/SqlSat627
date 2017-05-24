/*
Returns the total of the array. Expects specific format of OrderLines element.

//approach 1 - cool. unsupported. :(
function orderTotal(lines) {
    return lines.reduce( (total, line) => sum + (line["Quantity"] * line["StockItem"]["UnitPrice"]), 0);
}

//approach 2 - recursion
function orderTotal(arr) {
	var ele = arr.pop();
	var lineTotal = ele["Quantity"] * ele["StockItem"]["UnitPrice"];

	if (arr.length == 0) {
    	return lineTotal;

	} else {
  		return lineTotal + orderTotal(arr);

  	}
}

//approach 3 - loop (see below)
*/


function orderTotal(arr) {
    
	var total = 0;
    
	for (var i = 0; i < arr.length; i++) {
    
		total += (arr[i]["Quantity"] * arr[i]["StockItem"]["UnitPrice"]);
    
	}
    
	return total;
}
