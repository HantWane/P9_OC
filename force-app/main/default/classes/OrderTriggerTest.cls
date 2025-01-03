/**
 * Author: Antoine
 * Date: 03/01/2025
 * Description:
 * Test class for OrderTrigger and OrderService functionality.
 * This test class covers the functionality of handling order deletions,
 * net amount computation, and order-related updates on Account.
 */

@isTest
public class OrderTriggerTest {

    // Test case for the deletion of an order and its impact on the account's revenue.
    @isTest
    static void testTriggerOnOrderDelete() {
        // Create necessary test data (Account, Product, PricebookEntry, and Order)
        Account testAccount = DataFactory.createAccount('Test Account');
        Product2 testProduct = DataFactory.createProduct('Test Product');
        PricebookEntry testPricebookEntry = DataFactory.createPriceBookEntry(testProduct.Id, 100);
        Order orderToDelete = DataFactory.createOrder(testAccount.Id, 'Ordered', Date.today(), 50);

        // Creating a map for the order items associated with the order
        Map<String, Id> orderData = new Map<String, Id>{
            'Product2Id' => testProduct.Id,
            'PricebookEntryId' => testPricebookEntry.Id
        };
        List<OrderItem> testOrderItems = DataFactory.createOrderItems(
            new List<Order>{orderToDelete}, 
            orderData, 
            100.0
        );

        // Before deleting, verify the current values of order and account
        orderToDelete = [SELECT Id, NetAmount__c FROM Order WHERE Id = :orderToDelete.Id];
        System.debug('NetAmount before delete: ' + orderToDelete.NetAmount__c);
        Account accountBeforeDelete = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :testAccount.Id];

        // Perform the order deletion and check its impact
        Test.startTest();
        delete orderToDelete;
        Test.stopTest();

        // After deletion, check if the account's revenue (Chiffre_d_affaire__c) was updated as expected
        Account updatedAccount = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :testAccount.Id];
        Assert.areEqual(0, updatedAccount.Chiffre_d_affaire__c, 'Account revenue should be updated after order deletion.');
    }

    // Test case for calculating the net amount when order items exist
    @isTest
    static void testComputNetAmount() {
        // Create test data for the order and associated order items
        Account testAccount = DataFactory.createAccount('Test Account');
        Order order1 = DataFactory.createOrder(testAccount.Id, 'Ordered', Date.today(), 50);
        List<OrderItem> orderItems1 = new List<OrderItem>{
            new OrderItem(Quantity = 2, UnitPrice = 100),
            new OrderItem(Quantity = 1, UnitPrice = 150)
        };

        // Perform net amount calculation and validate
        OrderService.computeNetAmount(order1, orderItems1);
        Assert.areEqual(300, order1.NetAmount__c, 'Net amount calculation is incorrect.');
    }

    // Test case for calculating net amount when order items have zero quantities
    @isTest
    static void testComputNetAmountWithNoOrderItems() {
        // Create test data with no valid order items (zero quantities)
        Account testAccount = DataFactory.createAccount('Test Account');
        Order order1 = DataFactory.createOrder(testAccount.Id, 'Ordered', Date.today(), 50);

        // Order items with zero quantities
        List<OrderItem> orderItems1 = new List<OrderItem>{
            new OrderItem(Quantity = 0, UnitPrice = 100),
            new OrderItem(Quantity = 0, UnitPrice = 150)
        };

        // Calculate net amount and verify that it reflects only the shipment cost
        OrderService.computeNetAmount(order1, orderItems1);
        Assert.areEqual(-50, order1.NetAmount__c, 'Net amount should consider only shipment cost.');
    }

    // Test case for calculating the net amount when no order items are provided
    @isTest
    static void testComputNetAmountWithEmptyOrderItems() {
        // Create order with no items (empty list)
        Account testAccount = DataFactory.createAccount('Test Account');
        Order order = DataFactory.createOrder(testAccount.Id, 'Ordered', Date.today(), 50);
        List<OrderItem> orderItems = new List<OrderItem>();

        // Calculate net amount with no order items and verify the result
        OrderService.computeNetAmount(order, orderItems);
        Assert.areEqual(-50, order.NetAmount__c, 'Net amount with no items should equal negative shipment cost.');
    }

    // Test case for calculating the net amount with multiple orders
    @isTest
    static void testComputNetAmountWithMultipleOrders() {
        // Set up account, product, and pricebook entry for multiple orders
        Account testAccount = DataFactory.createAccount('Test Account');
        Product2 testProduct = DataFactory.createProduct('Test Product');
        PricebookEntry testPricebookEntry = DataFactory.createPriceBookEntry(testProduct.Id, 100);

        // Create multiple orders for the test
        List<Order> testOrders = DataFactory.createOrders(testAccount.Id, 101, 'Ordered', Date.today(), 50);
        Map<String, Id> orderData = new Map<String, Id>{
            'Product2Id' => testProduct.Id,
            'PricebookEntryId' => testPricebookEntry.Id
        };
        List<OrderItem> testOrderItems = DataFactory.createOrderItems(testOrders, orderData, 100.0);

        // Map the order items to their respective orders
        Map<Id, List<OrderItem>> orderToOrderItemsMap = new Map<Id, List<OrderItem>>();
        for (OrderItem orderItem : [SELECT OrderId, Quantity, UnitPrice FROM OrderItem WHERE OrderId IN :testOrders]) {
            // Ensure that order items are grouped by their order ID
            if (!orderToOrderItemsMap.containsKey(orderItem.OrderId)) {
                orderToOrderItemsMap.put(orderItem.OrderId, new List<OrderItem>());
            }
            orderToOrderItemsMap.get(orderItem.OrderId).add(orderItem);
        }

        // Verify the net amount calculation for each order
        for (Order testOrder : testOrders) {
            List<OrderItem> orderItemsForOrder = orderToOrderItemsMap.get(testOrder.Id);
            OrderService.computeNetAmount(testOrder, orderItemsForOrder);
            Assert.areEqual(50, testOrder.NetAmount__c, 'Net amount calculation failed for Order ID: ' + testOrder.Id);
        }
    }
}
