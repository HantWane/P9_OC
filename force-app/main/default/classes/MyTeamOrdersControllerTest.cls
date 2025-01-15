/**
 * Author: Antoine
 * Date: 03/01/2025
 * 
 * Description:
 * This class is responsible for tests of MyTeamOrdersController 
 * 
 **/

@IsTest
private class MyTeamOrdersControllerTest {

    // Method to set up common data for all tests
    @TestSetup
    static void makeData(){
        // Create a test account for the Eastern Sales Team
        Account acc1 = DataFactory.createAccount('Test Account 1');

        // Create a product
        Product2 product = DataFactory.createProduct('Test Product');

        // Create a PricebookEntry for the product in the standard Pricebook
        PricebookEntry pricebookEntry = DataFactory.createPriceBookEntry(product.Id, 100);

        // Create a test order with order lines for the Eastern Sales Team
        Order testOrder = DataFactory.createOrder(acc1.Id, 'Ordered', Date.newInstance(2024, 10, 10), 0);

        // Create OrderItems associated with the order
        Map<String, Id> orderData = new Map<String, Id>{
            'Product2Id' => product.Id,
            'PricebookEntryId' => pricebookEntry.Id
        };
        List<Order> ordersList = new List<Order>{testOrder};
        List<OrderItem> orderItems = DataFactory.createOrderItems(ordersList, orderData, 100);

        // Add a second OrderItem manually
        OrderItem additionalOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 150
        );
        insert additionalOrderItem;

        // Update the order to ensure totals are correctly calculated
        update testOrder;

        // Create a second account without orders for the Western Sales Team
        Account acc3 = DataFactory.createAccount('Test Account 3');

        // Associate the accounts with users of the respective teams
        User easternUser = [SELECT Id FROM User WHERE UserRole.Name = 'Eastern Sales Team' LIMIT 1];
        User westernUser = [SELECT Id FROM User WHERE UserRole.Name = 'Western Sales Team' LIMIT 1];

        acc1.OwnerId = easternUser.Id;
        acc3.OwnerId = westernUser.Id;
        update acc1;
        update acc3;
    }

    // Test to verify the calculation of SumOrders for the Eastern Sales Team
    @isTest
    static void testSumOrdersForEasternSalesTeam() {
        // Retrieve the user of the Eastern Sales Team
        User easternUser = [SELECT Id FROM User WHERE UserRole.Name = 'Eastern Sales Team' LIMIT 1];

        // Simulate the logged-in user
        System.runAs(easternUser) {
            // Create an instance of the controller
            MyTeamOrdersController controller = new MyTeamOrdersController();

            // Verify that the sum of orders is correct
            Test.startTest();
            decimal expectedSum = 250.0; // 100 + 150
            Assert.areEqual(expectedSum, controller.SumOrders, 'The sum of orders is incorrect for the Eastern Sales Team');
            Test.stopTest();
        }
    }

    @isTest
    static void testSumOrdersForWesternSalesTeam() {
        // Retrieve the user of the Western Sales Team
        User westernUser = [SELECT Id FROM User WHERE UserRole.Name = 'Western Sales Team' LIMIT 1];

        // Simulate the logged-in user
        System.runAs(westernUser) {
            // Create an instance of the controller
            MyTeamOrdersController controller = new MyTeamOrdersController();

            // Verify that the sum of orders is 0 when there are no orders
            Test.startTest();
            decimal expectedSum = 0.0;
            Assert.areEqual(expectedSum, controller.SumOrders, 'The sum of orders is incorrect for the Western Sales Team');
            Test.stopTest();
        }
    }
}
