/**
 * Test class for the UpdateAccountRevenueBatch class.
 *
 * Verifies that account revenue (`Chiffre_d_affaire__c`) is correctly updated
 * based on related orders using batch processing.
 *
 * Responsibilities:
 * - Create test data including Accounts, Products, Orders, and OrderItems using the `DataFactory` utility class.
 * - Execute the `UpdateAccountRevenueBatch` and validate the results.
 * - Ensure correctness of the `Chiffre_d_affaire__c` field calculation with a large number of orders (e.g., 101 orders).
 *
 * Features:
 * - Comprehensive test case simulating a real-world scenario with bulk data.
 * - Uses `Test.startTest()` and `Test.stopTest()` to validate asynchronous batch processing.
 * - Ensures scalability and correctness under Salesforce governor limits.
 *
 * Notes:
 * - This test case assumes that the `DataFactory` class is implemented correctly.
 * - Ensure that all required fields and objects are properly configured in the org before executing the test.
 * - Use this class to validate the functionality of the batch job in different scenarios and edge cases.
 *
 * Author: Antoine
 * Date: 03/01/2025
 */
@isTest
private class UpdateAccountRevenueBatchTest {

    /**
     * Test method to validate the `UpdateAccountRevenueBatch` with 101 orders.
     *
     * Responsibilities:
     * - Simulates the creation of test data using the `DataFactory` class.
     * - Verifies the correct calculation and update of the `Chiffre_d_affaire__c` field on the Account.
     * - Ensures proper functionality with a bulk data scenario (101 orders).
     *
     * Steps:
     * 1. Create test Account, Product, PricebookEntry, and Orders using `DataFactory`.
     * 2. Associate OrderItems with the created Orders.
     * 3. Execute the `UpdateAccountRevenueBatch` job using `Test.startTest()` and `Test.stopTest()`.
     * 4. Validate the `Chiffre_d_affaire__c` field on the Account.
     *
     * @throws AssertionException if the expected revenue does not match the actual value.
     */
    @isTest
    static void test2BatchWith101Orders() {
        // Step 1: Create a test account using DataFactory
        Account testAccount = DataFactory.createAccount('Test Account');

        // Step 2: Create a test product using DataFactory
        Product2 testProduct = DataFactory.createProduct('Test Product');

        // Step 3: Create a test PricebookEntry using DataFactory
        PricebookEntry testPricebookEntry = DataFactory.createPriceBookEntry(testProduct.Id, 100);

        // Step 4: Create 101 test orders using DataFactory
        List<Order> orders = DataFactory.createOrders(testAccount.Id, 'Ordered', Date.today(), 0, 101);

        // Step 5: Create order items for the orders using DataFactory
        Map<String, Id> orderData = new Map<String, Id>{
            'Product2Id' => testProduct.Id,
            'PricebookEntryId' => testPricebookEntry.Id
        };
        List<OrderItem> testOrderItems = DataFactory.createOrderItems(orders, orderData, 100.0);

        // Step 6: Execute the batch job
        Test.startTest();
        Set<Id> accountIds = new Set<Id>{testAccount.Id};
        UpdateAccountRevenueBatch batch = new UpdateAccountRevenueBatch(accountIds);
        Database.executeBatch(batch);
        Test.stopTest();

        // Step 7: Verify the Chiffre_d_affaire__c field is updated correctly
        testAccount = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :testAccount.Id];
        System.debug('Chiffre_d_affaire__c: ' + testAccount.Chiffre_d_affaire__c);

        // Expected revenue: 101 orders × 100 per order item = 10100
        Assert.areEqual(10100, testAccount.Chiffre_d_affaire__c,
            'The Chiffre_d_affaire__c field should be updated to 10100');
    }
}
