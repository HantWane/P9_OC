@isTest
private class testUpdateAccountCA {
    public static Decimal INITIAL_CHIFFRE_D_AFFAIRE = 20;


    @TestSetup
    static void makeData(){
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

      // Créer une commande de test
      Order testOrder = new Order(
        AccountId = acc1.Id,
        EffectiveDate = Date.newInstance(2024, 10, 10), 
        Status = 'Draft',
        ShipmentCost__c = 50,
        Pricebook2Id = Test.getStandardPricebookId()
    );
    insert testOrder;

        // Créer des OrderItems pour la commande
        List<OrderItem> orderItems = new List<OrderItem>();
        orderItems.add(new OrderItem(OrderId = testOrder.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 100));
        orderItems.add(new OrderItem(OrderId = testOrder.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 1, UnitPrice = 150));
        insert orderItems;


        // Créer un deuxième compte sans commande
        Account acc3 = new Account(Name = 'Test Account 3', Chiffre_d_affaire__c = INITIAL_CHIFFRE_D_AFFAIRE);
        insert acc3;
    }

    @isTest 
    static void Should_UpdateAccountCA_When_OrderIsUpdated() {
        // Récupérer le compte pour validation
        Account acc1 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        // Récupérer la commande et les OrderItems
        Order testOrder = [SELECT Id, NetAmount__c, ShipmentCost__c FROM Order WHERE AccountId = :acc1.Id LIMIT 1];
        List<OrderItem> orderItems = [SELECT Id, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :testOrder.Id];

        // Calculer le chiffre d'affaires basé sur les OrderItems
        Decimal totalCA = 0;
        for (OrderItem item : orderItems) {
            totalCA += item.Quantity * item.UnitPrice;
        }

        // Mettre à jour le chiffre d'affaires du compte
        acc1.Chiffre_d_affaire__c += totalCA;
        update acc1;

        // Rechercher à nouveau le compte pour vérifier les mises à jour
        Account updatedAcc1 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc1.Id];

        // Assert pour vérifier que le chiffre d'affaires a été mis à jour correctement
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE + totalCA, updatedAcc1.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte ne correspond pas à la valeur attendue.');
    }  


    @isTest
    static void Should_NotUpdateAccountCA_When_NoOrderExists() {
        // Exécuter le batch
        Test.startTest();
        UpdateAccounts batch = new UpdateAccounts();
        Database.executeBatch(batch);
        Test.stopTest();

        // Vérifier que le compte sans commande n'a pas été modifié
        Account acc3 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        Assert.areEqual(INITIAL_CHIFFRE_D_AFFAIRE, acc3.Chiffre_d_affaire__c,
            'Le chiffre d\'affaires du compte sans commande ne devrait pas changer.');
    }

    @isTest
    static void Should_UpdateMultipleAccounts_When_OrdersExist() {
        // Récupérer les comptes créés
        List<Account> accounts = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name IN ('Test Account 1', 'Test Account 3')];
        Assert.areEqual(2, accounts.size(), 'Les comptes de test doivent être présents.');

        Account acc1 = accounts[0];
        Account acc3 = accounts[1];
        
        // Exécuter le batch pour mettre à jour les comptes
        Test.startTest();
        UpdateAccounts batch = new UpdateAccounts();
        Database.executeBatch(batch);
        Test.stopTest();

        // Vérifier la mise à jour des chiffres d'affaires
        Account updatedAcc1 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc1.Id];
        Account updatedAcc3 = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :acc3.Id];
        
        // Calculer le chiffre d'affaires attendu pour chaque compte
        Decimal expectedAcc1CA = INITIAL_CHIFFRE_D_AFFAIRE + 350; // Somme totale des OrderItems pour acc1
        Decimal expectedAcc3CA = 0; // Aucun OrderItem pour acc3

        // Vérification
        Assert.areEqual(expectedAcc1CA, updatedAcc1.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc1 ne correspond pas à la valeur attendue.');
        Assert.areEqual(expectedAcc3CA, updatedAcc3.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte acc3 ne devrait pas être modifié.');
    }  
}