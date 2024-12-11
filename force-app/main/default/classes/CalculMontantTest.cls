@isTest
public class CalculMontantTest {

    @isTest
    static void testCalculateNetAmountAndUpdateAccountRevenue() {
        // Étape 1 : Création d'un compte pour tester les commandes
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        System.debug('Compte créé : ' + testAccount);

        // Étape 2 : Création d'un produit
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        System.debug('Produit créé : ' + product);

        // Étape 3 : Création d'une entrée dans le Pricebook
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;
        System.debug('PricebookEntry créé : ' + pricebookEntry);

        // Étape 4 : Création de la première commande avec des items
        Order order1 = new Order(
            AccountId = testAccount.Id,
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 50,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order1;
        System.debug('Commande 1 créée : ' + order1);
        

        // Ajout d'OrderItems à la commande
        List<OrderItem> orderItems1 = new List<OrderItem>{
            new OrderItem(OrderId = order1.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 100),
            new OrderItem(OrderId = order1.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 1, UnitPrice = 150)
        };
        insert orderItems1;
        System.debug('OrderItems pour la commande 1 : ' + orderItems1);
        update order1;

        // Étape 5 : Création de la deuxième commande avec des items
        Order order2 = new Order(
            AccountId = testAccount.Id,
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 100,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order2;
        System.debug('Commande 2 créée : ' + order2);

        List<OrderItem> orderItems2 = new List<OrderItem>{
            new OrderItem(OrderId = order2.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 3, UnitPrice = 200),
            new OrderItem(OrderId = order2.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 250)
        };
        insert orderItems2;
        update order2;
        System.debug('OrderItems pour la commande 2 : ' + orderItems2);
        System.debug('NetAmount__c pour Commande 2 après ajout des OrderItems : ' + order2.NetAmount__c);
        

        // Étape 6 : Vérification des calculs de montant net sur les commandes
        order1 = [SELECT Id, NetAmount__c, TotalAmount FROM Order WHERE Id = :order1.Id];
        order2 = [SELECT Id, NetAmount__c, TotalAmount FROM Order WHERE Id = :order2.Id];
        System.debug('total amount order 1:' + order1.TotalAmount);
        System.debug('Montant net de la commande 1 : ' + order1.NetAmount__c);
        System.debug('Montant net de la commande 2 : ' + order2.NetAmount__c);

        Decimal expectedNetAmount1 = (2 * 100) + (1 * 150) - 50; // (2x100) + (1x150) - 50
        Decimal expectedNetAmount2 = (3 * 200) + (2 * 250) - 100; // (3x200) + (2x250) - 100

        Assert.areEqual(expectedNetAmount1, order1.NetAmount__c, 'Le montant net pour la première commande est incorrect.');
        Assert.areEqual(expectedNetAmount2, order2.NetAmount__c, 'Le montant net pour la deuxième commande est incorrect.');


        // Simulation du batch
        Test.startTest();
        Database.executeBatch(new UpdateAccountRevenueBatch(new Set<Id>{testAccount.Id}));
        Test.stopTest();

        // Étape 7 : Vérification de la mise à jour du chiffre d'affaires sur le compte
        Account updatedAccount = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :testAccount.Id];
        Decimal expectedAccountCA = expectedNetAmount1 + expectedNetAmount2;
        System.debug('Chiffre d\'affaires attendu : ' + expectedAccountCA);
        System.debug('Chiffre d\'affaires réel : ' + updatedAccount.Chiffre_d_affaire__c);

        Assert.areEqual(expectedAccountCA, updatedAccount.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte est incorrect.');
    }

    @isTest
    static void testTriggerOnOrderDelete() {
        // Étape 1 : Création d'un compte
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        System.debug('Compte créé : ' + testAccount);

        // Étape 2 : Création d'une commande
        Order orderToDelete = new Order(
            AccountId = testAccount.Id,
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 50,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert orderToDelete;
        System.debug('Commande créée pour suppression : ' + orderToDelete);

        // Étape 3 : Création des OrderItems
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        System.debug('Produit créé : ' + product);

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;
        System.debug('PricebookEntry créé : ' + pricebookEntry);

        OrderItem orderItem = new OrderItem(
            OrderId = orderToDelete.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert orderItem;
        System.debug('OrderItem créé pour la commande à supprimer : ' + orderItem);
        update orderToDelete;

        // Vérification avant suppression
        orderToDelete = [SELECT NetAmount__c FROM Order WHERE Id = :orderToDelete.Id];
        System.debug('Montant net avant suppression : ' + orderToDelete.NetAmount__c);
        Assert.areEqual(150, orderToDelete.NetAmount__c, 'Le montant net avant suppression est incorrect.');

        // Suppression de la commande
        delete orderToDelete;
        System.debug('Commande supprimée.');

        // Vérification que le chiffre d'affaires est mis à jour après suppression
        Account updatedAccount = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :testAccount.Id];
        System.debug('Chiffre d\'affaires après suppression : ' + updatedAccount.Chiffre_d_affaire__c);
        Assert.areEqual(0, updatedAccount.Chiffre_d_affaire__c, 'Le chiffre d\'affaires après suppression est incorrect.');
    }

    @isTest
    static void testUpdateAccountWith101Orders() {
        // Étape 1 : Création d'un compte pour tester les commandes
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        System.debug('Compte créé : ' + testAccount);

        // Étape 2 : Création d'un produit
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        System.debug('Produit créé : ' + product);

        // Étape 3 : Création d'une entrée dans le Pricebook
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;
        System.debug('PricebookEntry créé : ' + pricebookEntry);

        // Étape 4 : Création de 101 commandes avec des items
        List<Order> orders = new List<Order>();
        List<OrderItem> orderItems = new List<OrderItem>();

        for (Integer i = 0; i < 101; i++) {
            Order order = new Order(
                AccountId = testAccount.Id,
                Status = 'Ordered',
                EffectiveDate = Date.today(),
                ShipmentCost__c = 10,
                Pricebook2Id = Test.getStandardPricebookId()
            );
            orders.add(order);
        }
        insert orders;
        System.debug('101 commandes créées.');

        for (Order order : orders) {
            OrderItem orderItem = new OrderItem(
                OrderId = order.Id,
                PricebookEntryId = pricebookEntry.Id,
                Quantity = 1,
                UnitPrice = 100
            );
            orderItems.add(orderItem);
        }
        insert orderItems;
        System.debug('OrderItems ajoutés aux 101 commandes.');
        update testAccount;

        // // Étape 5 : Vérification des calculs de montant net sur les commandes
        Decimal TotalAmount = 0;
        for (Order order : orders) {
            order = [SELECT Id, totalAmount, NetAmount__c FROM Order WHERE Id = :order.Id];
            TotalAmount += order.NetAmount__c;
            System.debug('Montant net de la commande ' + order.Id + ' : ' + order.NetAmount__c);
        

        Decimal expectedTotalAmount = 101 * (100 - 10); // 101 * (100 - 10)
        System.debug('Montant net total attendu : ' + expectedTotalAmount);
        System.debug('Montant net total réel : ' + TotalAmount);

        Assert.areEqual(expectedTotalAmount, TotalAmount, 'Le montant net total pour les 101 commandes est incorrect.');

        // Simulation du batch
        Test.startTest();
        Database.executeBatch(new UpdateAccountRevenueBatch(new Set<Id>{testAccount.Id}));
        Test.stopTest();

        // Étape 6 : Vérification de la mise à jour du chiffre d'affaires sur le compte
        Account updatedAccount = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :testAccount.Id];
        System.debug('Chiffre d\'affaires attendu : ' + expectedTotalAmount);
        System.debug('Chiffre d\'affaires réel : ' + updatedAccount.Chiffre_d_affaire__c);

        Assert.areEqual(expectedTotalAmount, updatedAccount.Chiffre_d_affaire__c, 'Le chiffre d\'affaires du compte est incorrect.');
    }
}

    @isTest
    static void testComputNetAmount() {
    
        // Étape 4 : Création de la première commande avec des items
        Order order1 = new Order(
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 50
        );
        System.debug('Commande 1 créée : ' + order1);
        

        // Ajout d'OrderItems à la commande
        List<OrderItem> orderItems1 = new List<OrderItem>{
            new OrderItem(Quantity = 2, UnitPrice = 100),
            new OrderItem(Quantity = 1, UnitPrice = 150)
        };
        System.debug('OrderItems pour la commande 1 : ' + orderItems1);

        OrderHelper.computNetAmount(order1, orderItems1);
        Assert.areEqual(300, order1.NetAmount__c);
    }

    @isTest
    static void testComputNetAmountwithNoOrderItems() {

        // Création de la première commande avec des items
        Order order1 = new Order(
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 50
        );
        System.debug('Commande 1 créée : ' + order1);
        

        // Ajout d'OrderItems à la commande
        List<OrderItem> orderItems1 = new List<OrderItem>{
            new OrderItem(Quantity = 0, UnitPrice = 100),
            new OrderItem(Quantity = 0, UnitPrice = 150)
        };
        System.debug('OrderItems pour la commande 1 : ' + orderItems1);

        OrderHelper.computNetAmount(order1, orderItems1);
        Assert.areEqual(-50, order1.NetAmount__c);
    }

        @isTest
    static void testComputNetAmountWithEmptyOrderItems() {
        // Étape 1 : Création de la commande sans items
        Order order = new Order(
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 50
        );
        System.debug('Commande créée : ' + order);

        // Étape 2 : Liste vide d'OrderItems
        List<OrderItem> orderItems = new List<OrderItem>();
        System.debug('OrderItems pour la commande : ' + orderItems);

        // Étape 3 : Appel de la méthode computNetAmount
        OrderHelper.computNetAmount(order, orderItems);

        // Étape 4 : Vérification du montant net calculé
        Decimal expectedNetAmount = 0 - 50; // -50
        System.debug('Montant net attendu : ' + expectedNetAmount);
        System.debug('Montant net calculé : ' + order.NetAmount__c);
        Assert.areEqual(expectedNetAmount, order.NetAmount__c, 'Le montant net calculé est incorrect.');
    }

}