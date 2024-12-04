@isTest
public with sharing class UpdateAccountsBatchTest {

    @TestSetup
    static void makeData(){
        List<Account> accountsList = new List<Account>();
        for (Integer i=0; i < 10; i++) {
            Account account = DataFactory.createAccount('testAccount' + i);
            accountsList.add(account);
        }
        insert accountsList;

        Product2 product = DataFactory.createProduct('testProduct');
        insert product;

        PricebookEntry pricebookEntry = DataFactory.createPriceBookEntry(product.Id, 100);
        insert pricebookEntry;

        Decimal unitPrice = pricebookEntry.UnitPrice;

        // 101 orders are created to confirm that if an account has more than 100 orders, it still can be updated
        List<Order> ordersList = new List<Order>();
        for (Account account : accountsList) {
            for (Integer i=0; i < 101; i++) {
                ordersList.add(DataFactory.createOrder(account.Id));
            }
        }
        insert ordersList;

        Map<String,String> productWithPricebookEntry = new Map<String,String> {
            'Product2Id' => product.Id,
            'PricebookEntryId' => pricebookEntry.Id
        };
        List<OrderItem> orderItemsList = DataFactory.createOrderItems(ordersList, productWithPricebookEntry, unitPrice);

        // Insert OrderItems in batches of 10,000
        Integer batchSize = 10000;
        Integer totalSize = orderItemsList.size();
        for (Integer i = 0; i < totalSize; i += batchSize) {
            List<OrderItem> batch = new List<OrderItem>();
            for (Integer j = i; j < Math.min(i + batchSize, totalSize); j++) {
                batch.add(orderItemsList[j]);
            }
            insert batch;
        }

        // Verify that orders and order items are correctly created
        System.assertEquals(1010, ordersList.size(), 'Expected 1010 orders');
        System.assertEquals(10100, orderItemsList.size(), 'Expected 10100 order items');
    }

    @isTest
    public static void updateAccountsBatchTest() {
        List<Order> ordersList = [SELECT Id, Status FROM Order LIMIT 1100];
        for (Order order : ordersList) {
            order.Status = 'Ordered';
        }
        update ordersList;

        Test.startTest();
        UpdateAccountsBatch updateAccountsBatch = new UpdateAccountsBatch();
        Id batchId = Database.executeBatch(updateAccountsBatch);
        Test.stopTest();

        // After the batch is executed, the Chiffre_d_affaire__c for each of the 10 accounts must equals the sum of total amount of all ordered orders
        Decimal expectedResult = 101000; // 101 orders * 10 products * 100 (unit price)
        List<Account> accountsList = [SELECT Id, Name, Chiffre_d_affaire__c FROM Account WHERE Name LIKE '%testAccount%'];
        for (Account account : accountsList) {
            System.assertEquals(expectedResult, account.Chiffre_d_affaire__c, 'Chiffre_d_affaire__c is '+ account.Chiffre_d_affaire__c+ '. Expected was ' + expectedResult +' on ' + account);
        }
    }
}
