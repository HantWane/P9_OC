trigger CalculMontant on Order (before insert, before update, after update, after insert, after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Calcul du montant net des commandes
            OrderHelper.calculateNetAmount(Trigger.new);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
            // Mise à jour du chiffre d'affaires des comptes
            Set<Id> accountIds = new Set<Id>();

            if (Trigger.isInsert || Trigger.isUpdate) {
                for (Order o : Trigger.new) {
                    accountIds.add(o.AccountId);
                }
            } else if (Trigger.isDelete) {
                for (Order o : Trigger.old) {
                    accountIds.add(o.AccountId);
                }
            }

            if (!accountIds.isEmpty()) {
                // Appel de la méthode de mise à jour via le batch
                OrderHelper.updateAccountRevenue(accountIds);
            }
        }
    }
}
