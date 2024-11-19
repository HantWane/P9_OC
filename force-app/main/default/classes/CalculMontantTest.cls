@isTest
private class TestCalculMontant {
    @isTest
    static void testBulkUpdate() {
        // Créer des commandes
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 10; i++) {
            orders.add(new Order(
                AccountId = null, // Remplacez par un ID valide si AccountId est requis
                EffectiveDate = Date.today(),
                Status = 'Draft',
                TotalAmount = 100 + i,
                ShipmentCost__c = 10 + i
            ));
        }
        insert orders;

        // Mise à jour des commandes
        for (Order order : orders) {
            order.TotalAmount += 50;
        }
        update orders;

        // Vérification
        List<Order> updatedOrders = [SELECT Id, NetAmount__c, TotalAmount, ShipmentCost__c FROM Order];
        for (Order order : updatedOrders) {
            Decimal expectedNetAmount = order.TotalAmount - order.ShipmentCost__c;
            System.assertEquals(expectedNetAmount, order.NetAmount__c, 'NetAmount__c incorrect pour l\'ID : ' + order.Id);
        }
    }
}
