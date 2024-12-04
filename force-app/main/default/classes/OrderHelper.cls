public class OrderHelper {
    public static Boolean HasRunOnce = false; 

    public static void calculateNetAmount(List<Order> newOrders) {
        System.debug('@calculateNetAmount afficher les orders : ' + newOrders);
        if (HasRunOnce == true){
            return;
        }
        // Collecter tous les IDs des commandes
        Set<Id> orderIds = new Set<Id>();
        for (Order o : newOrders) {
            if (o.Status == 'Ordered') {
                orderIds.add(o.Id);
            }
        }

        List<Order> orders = [SELECT Id, Status, EffectiveDate, AccountId, ShipmentCost__c, Pricebook2Id, NetAmount__c, totalAmount FROM Order WHERE Id IN :orderIds];

        // Effectuer une seule requête SOQL pour tous les OrderItem
        List<OrderItem> orderItems = [SELECT OrderId, Quantity, UnitPrice FROM OrderItem WHERE OrderId IN :orderIds];

        // Utiliser une map pour associer les OrderItem à leurs commandes
        Map<Id, List<OrderItem>> orderItemMap = new Map<Id, List<OrderItem>>();
        for (OrderItem item : orderItems) {
            if (!orderItemMap.containsKey(item.OrderId)) {
                orderItemMap.put(item.OrderId, new List<OrderItem>());
            }
            orderItemMap.get(item.OrderId).add(item);
        }

        // Calculer le montant net pour chaque commande
        for (Order o : orders) {
            if (o.Status == 'Ordered') {
                List<OrderItem> items = orderItemMap.get(o.Id);
                if (items != null) {
                    Decimal totalAmount = 0;
                    for (OrderItem item : items) {
                        totalAmount += item.Quantity * item.UnitPrice;
                    }
                    Decimal shipmentCost = o.ShipmentCost__c != null ? o.ShipmentCost__c : 0;
                    o.NetAmount__c = totalAmount - shipmentCost;
                }
            } else {
                o.NetAmount__c = null; // Si le statut n'est pas "Ordered", le montant net est null
            }
        }
        HasRunOnce = true;
        update orders;

        // Forcer une mise à jour "vide" pour déclencher les déclencheurs et workflows
        List<Order> ordersToUpdate = [SELECT Id FROM Order WHERE Id IN :orderIds];
        update ordersToUpdate;

    }

    public static void updateAccountRevenue(Set<Id> accountIds) {
        System.debug('SOQL queries before updateAccountRevenue: ' + Limits.getQueries());
        // Appel d'un batch pour mettre à jour les chiffres d'affaires
        Database.executeBatch(new UpdateAccountRevenueBatch(accountIds));
        System.debug('SOQL queries after updateAccountRevenue update: ' + Limits.getQueries());
    }
}
