@isTest
public class CalculMontantTest {

    
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
        Assert.areEqual(null, updatedAccount.Chiffre_d_affaire__c, 'Le chiffre d\'affaires après suppression est incorrect.');
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

        @isTest
        static void testComputNetAmountWithMultipleOrders() {
            // Étape 1 : Création d'un compte
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;

            // Étape 2 : Création d'un produit
            Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
            insert testProduct;
            System.debug('Produit créé : ' + testProduct);

            // Étape 3 : Création d'une entrée dans le Pricebook
            PricebookEntry testPricebookEntry = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct.Id,
                UnitPrice = 100,
                IsActive = true
            );
            insert testPricebookEntry;
            System.debug('PricebookEntry créé : ' + testPricebookEntry);

            // Étape 4 : Création de 101 commandes
            List<Order> testOrders = new List<Order>();
            for (Integer i = 0; i < 101; i++) {
                Order testOrder = new Order(
                    Status = 'Ordered',
                    EffectiveDate = Date.today(),
                    ShipmentCost__c = 50,
                    AccountId = testAccount.Id,
                    Pricebook2Id = Test.getStandardPricebookId()
                );
                testOrders.add(testOrder);
            }
            insert testOrders;

            // Étape 5 : Création des OrderItems pour chaque commande
            List<OrderItem> testOrderItems = new List<OrderItem>();
            for (Order testOrder : testOrders) {
                OrderItem testOrderItem = new OrderItem(
                    OrderId = testOrder.Id,
                    PricebookEntryId = testPricebookEntry.Id,
                    Quantity = 1,
                    UnitPrice = 100
                );
                testOrderItems.add(testOrderItem);
            }
            insert testOrderItems;

            // Étape 6 : Récupérer tous les OrderItems en une seule requête SOQL
            Map<Id, List<OrderItem>> orderToOrderItemsMap = new Map<Id, List<OrderItem>>();
            for (OrderItem orderItem : [SELECT OrderId, Quantity, UnitPrice FROM OrderItem WHERE OrderId IN :testOrders]) {
                if (!orderToOrderItemsMap.containsKey(orderItem.OrderId)) {
                    orderToOrderItemsMap.put(orderItem.OrderId, new List<OrderItem>());
                }
                orderToOrderItemsMap.get(orderItem.OrderId).add(orderItem);
            }

            // Étape 7 : Vérification du montant net calculé pour chaque commande
            for (Order testOrder : testOrders) {
                List<OrderItem> orderItemsForOrder = orderToOrderItemsMap.get(testOrder.Id);
                OrderHelper.computNetAmount(testOrder, orderItemsForOrder);
                System.debug('Montant net calculé pour la commande ' + testOrder.Id + ' : ' + testOrder.NetAmount__c);
                Assert.areEqual(50, testOrder.NetAmount__c, 'Le montant net calculé est incorrect pour la commande ' + testOrder.Id);
            }
        }

}