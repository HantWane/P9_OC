@isTest
private class UpdateAccountRevenueBatchTest {
    public static Decimal INITIAL_CHIFFRE_D_AFFAIRE = 20;

    @TestSetup
    static void makeData() {
        // Créer un compte de test
        Account acc1 = new Account(Name = 'Test Account 1', Chiffre_d_affaire__c = INITIAL_CHIFFRE_D_AFFAIRE);
        insert acc1;

        // Vérifier que le compte a été correctement inséré
        System.debug('Account 1 inserted with Chiffre_d_affaire__c: ' + acc1.Chiffre_d_affaire__c);

        // Ajouter un autre compte sans commande
        Account acc2 = new Account(Name = 'Test Account 2', Chiffre_d_affaire__c = INITIAL_CHIFFRE_D_AFFAIRE);
        insert acc2;
    }

    @isTest
    static void testUpdateAccountRevenueBatch() {
        // Récupérer les comptes créés
        List<Account> accounts = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name IN ('Test Account 1', 'Test Account 2')];
        Account acc1 = accounts[0];
        Account acc2 = accounts[1];

        // Debug pour vérifier les chiffres d'affaire avant le batch
        System.debug('Chiffre d\'affaire initial du compte 1: ' + acc1.Chiffre_d_affaire__c);
        System.debug('Chiffre d\'affaire initial du compte 2: ' + acc2.Chiffre_d_affaire__c);

        // Assert pour vérifier les chiffres d'affaire avant le batch
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE, acc1.Chiffre_d_affaire__c, 'Le chiffre d\'affaires initial du compte 1 est incorrect.');
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE, acc2.Chiffre_d_affaire__c, 'Le chiffre d\'affaires initial du compte 2 est incorrect.');
    }

    @isTest
    static void testAccountsWithNoOrders() {
        // Récupérer les comptes créés
        List<Account> accounts = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name IN ('Test Account 1', 'Test Account 2')];
        Account acc1 = accounts[0];
        Account acc2 = accounts[1];

        // Créer une instance du batch
        Set<Id> accountIds = new Set<Id>{acc1.Id, acc2.Id};
        UpdateAccountRevenueBatch batch = new UpdateAccountRevenueBatch(accountIds);

        // Exécuter le batch
        Test.startTest();
        Database.executeBatch(batch, 100);
        Test.stopTest();

        // Rechercher à nouveau les comptes pour vérifier les mises à jour
        Account updatedAcc1 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc1.Id];
        Account updatedAcc2 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc2.Id];

        // Vérifier les chiffres d'affaire après la mise à jour
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE, updatedAcc1.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc1 n\'a pas dû changer.');
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE, updatedAcc2.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc2 n\'a pas dû changer.');
    }

    

    @isTest
    static void testAccountsWithDifferentOrderAmounts() {
        // Créer un produit
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        // Créer un PricebookEntry
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;

        // Récupérer les comptes créés
        List<Account> accounts = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name IN ('Test Account 1', 'Test Account 2')];
        Account acc1 = accounts[0];

        // Créer des commandes avec différents montants
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 10; i++) {
            orders.add(new Order(
                AccountId = acc1.Id,
                EffectiveDate = Date.today(),
                Status = 'Ordered',
                Pricebook2Id = Test.getStandardPricebookId()
            ));
        }
        insert orders;

        // Créer des OrderItems pour la commande
        List<OrderItem> orderItems = new List<OrderItem>();
        for (Order order : orders) {
            orderItems.add(new OrderItem(OrderId = order.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 100));
        }
        insert orderItems;

        // Vérifier que les OrderItems ont été correctement créés
        System.assertNotEquals(0, [SELECT COUNT() FROM OrderItem WHERE OrderId IN :orders]);

        // Créer une instance du batch
        Set<Id> accountIds = new Set<Id>{acc1.Id};
        UpdateAccountRevenueBatch batch = new UpdateAccountRevenueBatch(accountIds);

        // Exécuter le batch
        Test.startTest();
        Database.executeBatch(batch, 100);
        Test.stopTest();

        // Rechercher à nouveau les comptes pour vérifier les mises à jour
        Account updatedAcc1 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc1.Id];

        // Calculer le chiffre d'affaires total de acc1 (10 commandes x 2 x 100 pour chaque OrderItem)
        Decimal totalCA = 10 * 2 * 100;

        // Vérifier les chiffres d'affaire après la mise à jour
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE + totalCA, updatedAcc1.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc1 n\'a pas été mis à jour correctement.');
    }
}
