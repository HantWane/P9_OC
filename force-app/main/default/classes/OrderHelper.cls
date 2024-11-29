public class OrderHelper {
    public static void calculateNetAmount(List<Order> orders) {
        System.debug('@calculateNetAmount afficher les orders : ' + orders);
        for (Order o : orders) {
            if (o.Status == 'Ordered') {
                // Calculer le montant total en utilisant les OrderItem
                List<OrderItem> orderItems = [SELECT Quantity, UnitPrice FROM OrderItem WHERE OrderId = :o.Id];
                Decimal totalAmount = 0;

                for (OrderItem item : orderItems) {
                    totalAmount += item.Quantity * item.UnitPrice;
                }

                Decimal shipmentCost = o.ShipmentCost__c != null ? o.ShipmentCost__c : 0;

                System.debug('totalAmount :' + totalAmount);
                System.debug('shipmentCost :' + shipmentCost);
                o.NetAmount__c = totalAmount - shipmentCost;
            } else {
                o.NetAmount__c = null; // Si le statut n'est pas "Ordered", le montant net est null
            }
        }
    }

    public static void updateAccountRevenue(Set<Id> accountIds) {
        System.debug('SOQL queries before updateAccountRevenue: ' + Limits.getQueries());
        // Appel d'un batch pour mettre à jour les chiffres d'affaires
        Database.executeBatch(new UpdateAccountRevenueBatch(accountIds));
        System.debug('SOQL queries after updateAccountRevenue update: ' + Limits.getQueries());
    }
}
