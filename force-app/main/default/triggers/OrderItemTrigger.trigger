trigger OrderItemTrigger on OrderItem (after insert, after update, after delete) {
    // Déclarer un ensemble pour stocker les IDs des commandes à mettre à jour
    Set<Id> orderIds = new Set<Id>();

    // Parcourir les OrderItems insérés ou mis à jour
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (OrderItem item : Trigger.new) {
            if (item.OrderId != null) {
                orderIds.add(item.OrderId);
            }
        }
    }

    // Parcourir les OrderItems supprimés
    if (Trigger.isDelete) {
        for (OrderItem item : Trigger.old) {
            if (item.OrderId != null) {
                orderIds.add(item.OrderId);
            }
        }
    }

    // Si des commandes doivent être mises à jour
    if (!orderIds.isEmpty()) {
        // Récupérer les commandes associées
        List<Order> ordersToUpdate = [SELECT Id, ShipmentCost__c, (SELECT Quantity, UnitPrice FROM OrderItems) FROM Order WHERE Id IN :orderIds];

        // Mettre à jour le montant net pour chaque commande
        for (Order order : ordersToUpdate) {
            OrderHelper.computNetAmount(order, order.OrderItems);
        }

        // Mettre à jour les commandes dans la base de données
        update ordersToUpdate;
    }
}
