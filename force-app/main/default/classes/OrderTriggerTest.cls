@isTest
public class OrderTriggerTest {

    @isTest
    static void testTriggerOnOrderDelete() {
        // Create a test account using DataFactory
        Account testAccount = DataFactory.createAccount('Test Account');

        // Create a test product using DataFactory
        Product2 testProduct = DataFactory.createProduct('Test Product');

        // Create a test PricebookEntry using DataFactory
        PricebookEntry testPricebookEntry = DataFactory.createPriceBookEntry(testProduct.Id, 100);

        // Create a test order using DataFactory
        Order orderToDelete = DataFactory.createOrder(testAccount.Id, 'Ordered', Date.today(), 50);

        // Create order items using DataFactory
        Map<String, Id> orderData = new Map<String, Id>{
            'Product2Id' => testProduct.Id,
            'PricebookEntryId' => testPricebookEntry.Id
        };
        List<Order> ordersList = new List<Order>{orderToDelete};
        List<OrderItem> testOrderItems = DataFactory.createOrderItems(ordersList, orderData, 100.0);

        // Debug pour voir le montant de la commande avant la requête SOQL
        System.debug('Montant de la commande avant la requête SOQL : ' + orderToDelete);

        // Vérification avant suppression
        orderToDelete = [SELECT Id, NetAmount__c, ShipmentCost__c FROM Order WHERE Id = :orderToDelete.Id];
        System.debug('Montant net avant suppression : ' + orderToDelete.NetAmount__c);

        // Debug pour voir combien le compte a en commandes avant suppression
        List<Order> ordersBeforeDelete = [SELECT Id, NetAmount__c, ShipmentCost__c FROM Order WHERE AccountId = :testAccount.Id];
        System.debug('Commandes avant suppression : ' + ordersBeforeDelete);

        // Debug pour voir les éléments de commande avant suppression
        List<OrderItem> orderItemsBeforeDelete = [SELECT Id, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :orderToDelete.Id];
        System.debug('Éléments de commande avant suppression : ' + orderItemsBeforeDelete);

        // Suppression de la commande
        delete orderToDelete;
        System.debug('Commande supprimée.');

        // Debug pour voir combien le compte a en commandes après suppression
        List<Order> ordersAfterDelete = [SELECT Id, NetAmount__c, ShipmentCost__c FROM Order WHERE AccountId = :testAccount.Id];
        System.debug('Commandes après suppression : ' + ordersAfterDelete);

        // Vérification que le chiffre d'affaires est mis à jour après suppression
        Account updatedAccount = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :testAccount.Id];
        System.debug('Chiffre d\'affaires après suppression : ' + updatedAccount.Chiffre_d_affaire__c);

        // Calcul du montant net attendu après suppression
        Decimal expectedNetAmountAfterDelete = orderToDelete.ShipmentCost__c;
        System.debug('Montant net attendu après suppression : ' + expectedNetAmountAfterDelete);

        // Vérification que le montant net après suppression est correct
        Assert.areEqual(null, updatedAccount.Chiffre_d_affaire__c, 'Le montant net après suppression est incorrect.');
    }

    @isTest
    static void testComputNetAmount() {
        // Create a test account using DataFactory
        Account testAccount = DataFactory.createAccount('Test Account');

        // Create a test order using DataFactory
        Order order1 = DataFactory.createOrder(testAccount.Id, 'Ordered', Date.today(), 50);

        // Create order items
        List<OrderItem> orderItems1 = new List<OrderItem>{
            new OrderItem(Quantity = 2, UnitPrice = 100),
            new OrderItem(Quantity = 1, UnitPrice = 150)
        };

        OrderHelper.computNetAmount(order1, orderItems1);
        Assert.areEqual(300, order1.NetAmount__c);
    }

    @isTest
    static void testComputNetAmountwithNoOrderItems() {
        // Create a test account using DataFactory
        Account testAccount = DataFactory.createAccount('Test Account');

        // Create a test order using DataFactory
        Order order1 = DataFactory.createOrder(testAccount.Id, 'Ordered', Date.today(), 50);

        // Create order items with zero quantity
        List<OrderItem> orderItems1 = new List<OrderItem>{
            new OrderItem(Quantity = 0, UnitPrice = 100),
            new OrderItem(Quantity = 0, UnitPrice = 150)
        };

        OrderHelper.computNetAmount(order1, orderItems1);
        Assert.areEqual(-50, order1.NetAmount__c);
    }

    @isTest
    static void testComputNetAmountWithEmptyOrderItems() {
        // Create a test account using DataFactory
        Account testAccount = DataFactory.createAccount('Test Account');

        // Create a test order using DataFactory
        Order order = DataFactory.createOrder(testAccount.Id, 'Ordered', Date.today(), 50);

        // Empty list of OrderItems
        List<OrderItem> orderItems = new List<OrderItem>();

        // Call the computNetAmount method
        OrderHelper.computNetAmount(order, orderItems);

        // Verify the calculated net amount
        Decimal expectedNetAmount = 0 - 50; // -50
        System.debug('Montant net attendu : ' + expectedNetAmount);
        System.debug('Montant net calculé : ' + order.NetAmount__c);
        Assert.areEqual(expectedNetAmount, order.NetAmount__c, 'Le montant net calculé est incorrect.');
    }

    @isTest
    static void testComputNetAmountWithMultipleOrders() {
        // Create a test account using DataFactory
        Account testAccount = DataFactory.createAccount('Test Account');

        // Create a test product using DataFactory
        Product2 testProduct = DataFactory.createProduct('Test Product');

        // Create a test PricebookEntry using DataFactory
        PricebookEntry testPricebookEntry = DataFactory.createPriceBookEntry(testProduct.Id, 100);

        // Create 101 test orders using DataFactory
        List<Order> testOrders = DataFactory.createOrders(testAccount.Id, 101, 'Ordered', Date.today(), 50);

        // Create order items using DataFactory
        Map<String, Id> orderData = new Map<String, Id>{
            'Product2Id' => testProduct.Id,
            'PricebookEntryId' => testPricebookEntry.Id
        };
        List<OrderItem> testOrderItems = DataFactory.createOrderItems(testOrders, orderData, 100.0);

        // Retrieve all OrderItems in a single SOQL query
        Map<Id, List<OrderItem>> orderToOrderItemsMap = new Map<Id, List<OrderItem>>();
        for (OrderItem orderItem : [SELECT OrderId, Quantity, UnitPrice FROM OrderItem WHERE OrderId IN :testOrders]) {
            if (!orderToOrderItemsMap.containsKey(orderItem.OrderId)) {
                orderToOrderItemsMap.put(orderItem.OrderId, new List<OrderItem>());
            }
            orderToOrderItemsMap.get(orderItem.OrderId).add(orderItem);
        }

        // Verify the calculated net amount for each order
        for (Order testOrder : testOrders) {
            List<OrderItem> orderItemsForOrder = orderToOrderItemsMap.get(testOrder.Id);
            OrderHelper.computNetAmount(testOrder, orderItemsForOrder);
            System.debug('Montant net calculé pour la commande ' + testOrder.Id + ' : ' + testOrder.NetAmount__c);
            Assert.areEqual(50, testOrder.NetAmount__c, 'Le montant net calculé est incorrect pour la commande ' + testOrder.Id);
        }
    }
}
