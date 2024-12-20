@isTest
private class UpdateAccountRevenueBatchTest {
    // public static Decimal INITIAL_CHIFFRE_D_AFFAIRE = 20;

    // @TestSetup
    // static void makeData() {
    //     // Créer un compte de test
    //     Account acc1 = new Account(Name = 'Test Account 1', Chiffre_d_affaire__c = INITIAL_CHIFFRE_D_AFFAIRE);
    //     insert acc1;

    //     // Ajouter un autre compte sans commande
    //     Account acc2 = new Account(Name = 'Test Account 2', Chiffre_d_affaire__c = INITIAL_CHIFFRE_D_AFFAIRE);
    //     insert acc2;
    // }

    // @isTest
    // static void testUpdateAccountRevenueBatchNoOrders() {
    //     // Récupérer les comptes créés
    //     List<Account> accounts = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name IN ('Test Account 1', 'Test Account 2')];
    //     Account acc1 = accounts[0];
    //     Account acc2 = accounts[1];

    //     // Créer une instance du batch
    //     Set<Id> accountIds = new Set<Id>{acc1.Id, acc2.Id};
    //     UpdateAccountRevenueBatch batch = new UpdateAccountRevenueBatch(accountIds);

    //     // Exécuter le batch
    //     Test.startTest();
    //     Database.executeBatch(batch, 100);
    //     Test.stopTest();

    //     // Rechercher à nouveau les comptes pour vérifier les mises à jour
    //     Account updatedAcc1 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc1.Id];
    //     Account updatedAcc2 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc2.Id];

    //     // Vérifier les chiffres d'affaire après la mise à jour (aucune commande, donc 0)
    //     System.assertEquals(0, updatedAcc1.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc1 aurait dû être remis à 0.');
    //     System.assertEquals(0, updatedAcc2.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc2 aurait dû être remis à 0.');
    // }

    // @isTest
    // static void testUpdateAccountRevenueBatchWithOrders() {
    //     // Créer un produit
    //     Product2 product = new Product2(Name = 'Test Product', IsActive = true);
    //     insert product;

    //     // Créer un PricebookEntry
    //     PricebookEntry pricebookEntry = new PricebookEntry(
    //         Pricebook2Id = Test.getStandardPricebookId(),
    //         Product2Id = product.Id,
    //         UnitPrice = 100,
    //         IsActive = true
    //     );
    //     insert pricebookEntry;

    //     // Récupérer le compte créé
    //     Account acc1 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Test Account 1'];

    //     // Créer des commandes avec différents montants
    //     List<Order> orders = new List<Order>();
    //     for (Integer i = 0; i < 10; i++) {
    //         orders.add(new Order(
    //             AccountId = acc1.Id,
    //             EffectiveDate = Date.today(),
    //             Status = 'Ordered',
    //             Pricebook2Id = Test.getStandardPricebookId()
    //         ));
    //     }
    //     insert orders;

    //     // Créer des OrderItems pour les commandes
    //     List<OrderItem> orderItems = new List<OrderItem>();
    //     for (Order order : orders) {
    //         orderItems.add(new OrderItem(OrderId = order.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 100));
    //     }
    //     insert orderItems;

    //     // Vérifier que les OrderItems ont été correctement créés
    //     System.assertNotEquals(0, [SELECT COUNT() FROM OrderItem WHERE OrderId IN :orders]);

    //     // Créer une instance du batch
    //     Set<Id> accountIds = new Set<Id>{acc1.Id};
    //     UpdateAccountRevenueBatch batch = new UpdateAccountRevenueBatch(accountIds);

    //     // Exécuter le batch
    //     Test.startTest();
    //     Database.executeBatch(batch, 100);
    //     Test.stopTest();

    //     // Rechercher à nouveau le compte pour vérifier les mises à jour
    //     Account updatedAcc1 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc1.Id];

    //     // Calculer le chiffre d'affaires total de acc1 (10 commandes x 2 x 100 pour chaque OrderItem)
    //     Decimal totalCA = 10 * 2 * 100;

    //     // Vérifier les chiffres d'affaire après la mise à jour
    //     System.assertEquals(totalCA, updatedAcc1.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc1 n\'a pas été mis à jour correctement.');
    // }

    @isTest
    static void testBatchWith101Orders() {
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create 101 test orders with a total amount of 1010
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 101; i++) {
            Order order = new Order(
                AccountId = testAccount.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = Test.getStandardPricebookId()
            );
            orders.add(order);
        }
        insert orders;

        // Ensure the orders are correctly linked to the account
        testAccount = [SELECT Id, (SELECT TotalAmount FROM Orders) FROM Account WHERE Id = :testAccount.Id];
        System.assert(testAccount.Orders.size() == 101, 'The account should have 101 orders');

        // Execute the batch
        Test.startTest();
        UpdateAccountRevenueBatch batch = new UpdateAccountRevenueBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify the Chiffre_d_affaire__c field is updated correctly
        testAccount = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :testAccount.Id];
        System.debug('Chiffre_d_affaire__c: ' + testAccount.Chiffre_d_affaire__c);
        System.assertEquals(1010, testAccount.Chiffre_d_affaire__c, 'The Chiffre_d_affaire__c field should be updated to 1010');
    }
}
