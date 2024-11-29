@isTest
private class UpdateAccountRevenueBatchTest {
    public static Decimal INITIAL_CHIFFRE_D_AFFAIRE = 20;

    @TestSetup
    static void makeData() {
        // Créer un compte de test
        Account acc1 = new Account(Name = 'Test Account 1');
        acc1.Chiffre_d_affaire__c = INITIAL_CHIFFRE_D_AFFAIRE;
        insert acc1;

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

        // Créer 100 commandes
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 100; i++) {
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

        // Assert pour vérifier les chiffres d'affaire avant le batch
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE, acc1.Chiffre_d_affaire__c, 'Le chiffre d\'affaires initial du compte 1 est incorrect.');
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE, acc2.Chiffre_d_affaire__c, 'Le chiffre d\'affaires initial du compte 2 est incorrect.');

        // Créer une instance du batch
        Set<Id> accountIds = new Set<Id>{acc1.Id, acc2.Id};
        UpdateAccountRevenueBatch batch = new UpdateAccountRevenueBatch(accountIds);

        // Exécuter le batch
        System.debug('SOQL queries before batch execution: ' + Limits.getQueries());
        Test.startTest();
        Database.executeBatch(batch, 200); // Augmenter la taille de la batch pour éviter trop de requêtes
        Test.stopTest();
        System.debug('SOQL queries after batch execution: ' + Limits.getQueries());

        // Rechercher à nouveau les comptes pour vérifier les mises à jour
        Account updatedAcc1 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc1.Id];
        Account updatedAcc2 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc2.Id];

        // Calculer le chiffre d'affaires total de acc1 (100 commandes x 2 x 100 pour chaque OrderItem)
        Decimal totalCA = 100 * 2 * 100;

        // Vérifier les chiffres d'affaire après la mise à jour
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE + totalCA, updatedAcc1.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc1 n\'a pas été mis à jour correctement.');
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE, updatedAcc2.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc2 n\'a pas dû changer.');

        // Log the number of SOQL queries
        System.debug('Number of SOQL queries: ' + Limits.getQueries());
    }
}
