@IsTest
private class testMyTeamOrdersController {

    // Méthode de configuration des données communes à tous les tests
    @TestSetup
    static void makeData(){
        // Créer un compte de test pour l'équipe Eastern Sales Team
        Account acc1 = new Account(Name = 'Test Account 1');
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

        // Créer une commande de test avec des lignes de commande pour l'équipe Eastern Sales Team
        Order testOrder = new Order(
            AccountId = acc1.Id,
            EffectiveDate = Date.newInstance(2024, 10, 10),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOrder;

        // Créer des OrderItems associés à la commande
        List<OrderItem> orderItems = new List<OrderItem>();
        orderItems.add(new OrderItem(OrderId = testOrder.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 2, UnitPrice = 100));
        orderItems.add(new OrderItem(OrderId = testOrder.Id, PricebookEntryId = pricebookEntry.Id, Quantity = 1, UnitPrice = 150));
        insert orderItems;
        update testOrder;

        // Créer un deuxième compte sans commande pour l'équipe Western Sales Team
        Account acc3 = new Account(Name = 'Test Account 3');
        insert acc3;
    }

    // Test pour vérifier le calcul de SumOrders pour l'équipe Eastern Sales Team
    @IsTest
    static void testSumOrdersEasternTeam() {
        // Récupérer l'utilisateur existant avec le rôle "Eastern Sales Team"
        User easternUser = [SELECT Id FROM User WHERE UserRole.Name = 'Eastern Sales Team' LIMIT 1];

        // Instancier la classe du contrôleur à tester
        MyTeamOrdersController controller = new MyTeamOrdersController();

        // Simuler l'utilisateur connecté comme étant de l'équipe Eastern Sales Team
        System.runAs(easternUser) {
            // Appeler la méthode SumOrders pour obtenir le total des commandes
            Decimal sumOrders = controller.SumOrders;

            // Calcul attendu : (2 * 100) + (1 * 150) = 350
            Decimal expectedSum = 350;

            // Assertion pour vérifier que le total calculé est correct
            System.assertEquals(expectedSum, sumOrders, 'La somme des commandes devrait être égale à 350');
        }
    }

    // Test pour vérifier le calcul de SumOrders pour l'équipe Western Sales Team
    @IsTest
    static void testSumOrdersWesternTeam() {
        // Récupérer l'utilisateur existant avec le rôle "Western Sales Team"
        User westernUser = [SELECT Id FROM User WHERE UserRole.Name = 'Western Sales Team' LIMIT 1];

        // Instancier la classe du contrôleur à tester
        MyTeamOrdersController controller = new MyTeamOrdersController();

        // Simuler l'utilisateur connecté comme étant de l'équipe Western Sales Team
        System.runAs(westernUser) {
            // Appeler la méthode SumOrders pour obtenir le total des commandes
            Decimal sumOrders = controller.SumOrders;

            // Calcul attendu : 0 (puisqu'il n'y a pas de commandes pour cette équipe)
            Decimal expectedSum = 0;

            // Assertion pour vérifier que le total calculé est correct
            System.assertEquals(expectedSum, sumOrders, 'La somme des commandes devrait être égale à 0');
        }
    }
}
