@IsTest
private class testMyTeamOrdersController {
    
    // Méthode de configuration des données communes à tous les tests
    @TestSetup
    static void makeData(){
        // Créer un compte de test
        Account acc1 = new Account(Name = 'Test Account 1');
        acc1.Chiffre_d_affaire__c = 50000; // Exemple de valeur
        insert acc1;

        // Créer un produit
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;

        // Créer un PricebookEntry pour le produit dans le Pricebook standard
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;

        // Créer une commande de test avec des lignes de commande
        Order testOrder = new Order(
            AccountId = acc1.Id,
            EffectiveDate = Date.newInstance(2024, 10, 10), 
            Status = 'Draft',
            ShipmentCost__c = 50,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOrder;

        // Créer des OrderItems associés à la commande
        List<OrderItem> orderItems = new List<OrderItem>();
        orderItems.add(new OrderItem(OrderId = testOrder.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 100));
        orderItems.add(new OrderItem(OrderId = testOrder.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 1, UnitPrice = 150));
        insert orderItems;

        // Créer un deuxième compte sans commande
        Account acc3 = new Account(Name = 'Test Account 3', Chiffre_d_affaire__c = 30000); // Exemple de valeur
        insert acc3;
    }

    // Test pour vérifier le calcul de SumOders
    @IsTest
    static void testSumOrders() {
        // Instancier la classe du contrôleur à tester
        MyTeamOrdersController controller = new MyTeamOrdersController();
        
        // Appeler la méthode SumOders pour obtenir le total des commandes
        Decimal sumOrders = controller.SumOders;

        // Calcul attendu : (2 * 100) + (1 * 150) = 350
        Decimal expectedSum = 350;

        // Assertion pour vérifier que le total calculé est correct
        Assert.areEqual(expectedSum, sumOrders, 'La somme des commandes devrait être égale à 350');
    }
}
