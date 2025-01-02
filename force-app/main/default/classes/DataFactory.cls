public with sharing class DataFactory {

    public static Account createAccount(String accountName) {
        Account acc = new Account(Name = accountName);
        insert acc;
        return acc;
    }

    public static Product2 createProduct(String productName) {
        Product2 prod = new Product2(Name = productName, IsActive = true);
        insert prod;
        return prod;
    }

    public static PricebookEntry createPriceBookEntry(Id product2Id, Double unitPrice) {
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product2Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pricebookEntry;
        return pricebookEntry;
    }

    public static Order createOrder(Id accountId, String status, Date effectiveDate, Decimal shipmentCost) {
        Order order = new Order(
            AccountId = accountId,
            Status = status,
            EffectiveDate = effectiveDate,
            ShipmentCost__c = shipmentCost,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;
        return order;
    }

    public static List<Order> createOrders(Id accountId, Integer numberOfOrders, String status, Date effectiveDate, Decimal shipmentCost) {
        List<Order> ordersList = new List<Order>();
        for (Integer i = 0; i < numberOfOrders; i++) {
            Order order = new Order(
                AccountId = accountId,
                Status = status,
                EffectiveDate = effectiveDate,
                ShipmentCost__c = shipmentCost,
                Pricebook2Id = Test.getStandardPricebookId()
            );
            ordersList.add(order);
        }
        insert ordersList;
        return ordersList;
    }

    public static List<OrderItem> createOrderItems(List<Order> ordersList, Map<String, Id> orderData, Decimal unitPrice) {
        List<OrderItem> orderItems = new List<OrderItem>();
        for (Order order : ordersList) {
            OrderItem orderItem = new OrderItem(
                OrderId = order.Id,
                Product2Id = orderData.get('Product2Id'),
                PricebookEntryId = orderData.get('PricebookEntryId'),
                Quantity = 1, // Each order item has a quantity of 1
                UnitPrice = unitPrice
            );
            orderItems.add(orderItem);
        }
        insert orderItems;
        return orderItems;
    }
}
