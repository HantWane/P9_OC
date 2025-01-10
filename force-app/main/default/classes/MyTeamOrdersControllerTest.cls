@IsTest
private class MyTeamOrdersControllerTest {

    // Méthode de configuration des données communes à tous les tests
    @TestSetup
    static void makeData(){
        // Créer un compte de test pour l'équipe Eastern Sales Team
        Account acc1 = DataFactory.createAccount('Test Account 1');

        // Créer un produit
        Product2 product = DataFactory.createProduct('Test Product');

        // Créer un PricebookEntry pour le produit dans le Pricebook standard
        PricebookEntry pricebookEntry = DataFactory.createPriceBookEntry(product.Id, 100);

        // Créer une commande de test avec des lignes de commande pour l'équipe Eastern Sales Team
        Order testOrder = DataFactory.createOrder(acc1.Id, 'Ordered', Date.newInstance(2024, 10, 10), 0);

        // Créer des OrderItems associés à la commande
        Map<String, Id> orderData = new Map<String, Id>{
            'Product2Id' => product.Id,
            'PricebookEntryId' => pricebookEntry.Id
        };
        List<Order> ordersList = new List<Order>{testOrder};
        List<OrderItem> orderItems = DataFactory.createOrderItems(ordersList, orderData, 100);

        // Ajouter un deuxième OrderItem manuellement
        OrderItem additionalOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 150
        );
        insert additionalOrderItem;

        // Mettre à jour la commande pour s'assurer que les totaux sont correctement calculés
        update testOrder;

        // Créer un deuxième compte sans commande pour l'équipe Western Sales Team
        Account acc3 = DataFactory.createAccount('Test Account 3');

        // Associer les comptes aux utilisateurs des équipes respectives
        User easternUser = [SELECT Id FROM User WHERE UserRole.Name = 'Eastern Sales Team' LIMIT 1];
        User westernUser = [SELECT Id FROM User WHERE UserRole.Name = 'Western Sales Team' LIMIT 1];

        acc1.OwnerId = easternUser.Id;
        acc3.OwnerId = westernUser.Id;
        update acc1;
        update acc3;
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

            // Calcul attendu : 100 + (1 * 150) = 350
            Decimal expectedSum = 250;

            // Assertion pour vérifier que le total calculé est correct
            Assert.areEqual(expectedSum, sumOrders, 'La somme des commandes devrait être égale à 250');
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
            Assert.areEqual(expectedSum, sumOrders, 'La somme des commandes devrait être égale à 0');
        }
    }
}
