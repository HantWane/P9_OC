@isTest
public class OrderItemTriggerTest {

    @isTest
    static void testOrderItemTrigger() {
        // Étape 1 : Création d'un compte
        Account account = new Account(Name = 'Test Account');
        insert account;

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

        // Étape 1 : Création de la commande
        Order order = new Order(
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 50,
            AccountId = account.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;

        // Étape 2 : Création des articles de commande
        List<OrderItem> orderItems = new List<OrderItem>{
            new OrderItem(OrderId = order.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 100),
            new OrderItem(OrderId = order.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 1, UnitPrice = 150)
        };
        insert orderItems;

        // Étape 3 : Vérification du montant net calculé
        order = [SELECT NetAmount__c FROM Order WHERE Id = :order.Id];
        Decimal expectedNetAmount = (2 * 100 + 1 * 150) - 50; // 200 + 150 - 50 = 300
        System.debug('Montant net attendu : ' + expectedNetAmount);
        System.debug('Montant net calculé : ' + order.NetAmount__c);
        Assert.areEqual(expectedNetAmount, order.NetAmount__c, 'Le montant net calculé est incorrect.');
    }

    @isTest
    static void testOrderItemTriggerWithEmptyOrderItems() {
        // Étape 1 : Création d'un compte
        Account account = new Account(Name = 'Test Account');
        insert account;

        // Étape 2 : Création de la commande sans items
        Order order = new Order(
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 50,
            AccountId = account.Id
        );
        insert order;

        // Étape 3 : Vérification du montant net calculé
        order = [SELECT NetAmount__c FROM Order WHERE Id = :order.Id];
        Decimal expectedNetAmount = 0 - 50; // -50
        System.debug('Montant net attendu : ' + expectedNetAmount);
        System.debug('Montant net calculé : ' + order.NetAmount__c);
        Assert.areEqual(expectedNetAmount, order.NetAmount__c, 'Le montant net calculé est incorrect.');
    }

    @isTest
    static void testOrderItemTriggerWithUpdatedOrderItems() {
        // Étape 1 : Création d'un compte
        Account account = new Account(Name = 'Test Account');
        insert account;

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

        // Étape 1 : Création de la commande
        Order order = new Order(
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 50,
            AccountId = account.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;

        // Étape 2 : Création des articles de commande
        List<OrderItem> orderItems = new List<OrderItem>{
            new OrderItem(OrderId = order.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 100),
            new OrderItem(OrderId = order.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 1, UnitPrice = 150)
        };
        insert orderItems;

        // Étape 3 : Mise à jour des articles de commande
        orderItems[0].Quantity = 3;
        orderItems[1].UnitPrice = 200;
        update orderItems;

        // Étape 4 : Vérification du montant net calculé
        order = [SELECT NetAmount__c FROM Order WHERE Id = :order.Id];
        Decimal expectedNetAmount = (3 * 100 + 1 * 200) - 50; // 300 + 200 - 50 = 450
        System.debug('Montant net attendu : ' + expectedNetAmount);
        System.debug('Montant net calculé : ' + order.NetAmount__c);
        Assert.areEqual(expectedNetAmount, order.NetAmount__c, 'Le montant net calculé est incorrect.');
    }

    @isTest
    static void testOrderItemTriggerWithDeletedOrderItem() {
        // Étape 1 : Création d'un compte
        Account account = new Account(Name = 'Test Account');
        insert account;

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

        // Étape 4 : Création de la commande
        Order order = new Order(
            Status = 'Ordered',
            EffectiveDate = Date.today(),
            ShipmentCost__c = 50,
            AccountId = account.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;

        // Étape 5 : Création des articles de commande
        List<OrderItem> orderItems = new List<OrderItem>{
            new OrderItem(OrderId = order.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 100),
            new OrderItem(OrderId = order.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 1, UnitPrice = 150)
        };
        insert orderItems;

        // Étape 6 : Suppression d'un article de commande
        delete orderItems[0];

        // Étape 7 : Vérification du montant net calculé
        order = [SELECT NetAmount__c FROM Order WHERE Id = :order.Id];
        Decimal expectedNetAmount = (1 * 150) - 50; // 150 - 50 = 100
        System.debug('Montant net attendu : ' + expectedNetAmount);
        System.debug('Montant net calculé : ' + order.NetAmount__c);
        Assert.areEqual(expectedNetAmount, order.NetAmount__c, 'Le montant net calculé est incorrect.');
    }
}
