function joinOrderSalesperson() {
    var context = getContext()
    var collection = context.getCollection();
    var response = context.getResponse();

    var isAccepted = collection.queryDocuments(collection.getSelfLink(),
        'SELECT p.PersonId, p.FullName FROM p WHERE p.EntityType = "Person" ORDER BY p.PersonId',
        function (err, tblPerson, options) {
            if (err) throw err;

            // Check if the feed is empty 
            if (!tblPerson || !tblPerson.length) {
                response.setBody('no data');
            }

            else {
                var isAccepted = collection.queryDocuments(collection.getSelfLink(),
                'SELECT o.OrderId, udf.fnOrderTotal(o.OrderLines) AS OrderTotal, o.SalespersonPersonId FROM o WHERE o.EntityType = "Order" ORDER BY o.SalespersonPersonId',
                function (err, tblOrder, options) {
                    if (err) throw err;

                    // Check if the feed is empty
                    if (!tblOrder || !tblOrder.length) {
                        response.setBody('no data');
                    }

                    else {
                        result = [];

                        var j = 0;

                        for (i = 0; i < tblPerson.length; i++) {                        //outer loop, Person.PersonId
                            var personId = tblPerson[i]["PersonId"];
                            
                            inner:
                            while (j < tblOrder.length) {                               //inner loop, Order.SalespersonPersonId
                                var salespersonPersonId = tblOrder[j]["SalespersonPersonId"];
                                
                                if (salespersonPersonId == personId) {                  //when matched, add to result set
                                    result.push({
                                        PersonId : tblPerson[i]["PersonId"],
                                        FullName: tblPerson[i]["FullName"],
                                        OrderId : tblOrder[j]["OrderId"],
                                        OrderTotal: tblOrder[j]["OrderTotal"]
                                    });
                                }
                                
                                else if (salespersonPersonId > personId) {              //if inner loop is ahead of outer, break
                                    break inner;
                                }
                                
                                j++;                                                    //advance inner loop
                            }
                        }

                        response.setBody(JSON.stringify(result));
                    }
                });

            }
        });
}