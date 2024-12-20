trigger CalculMontant on Order (before insert, before update, after insert, after update, after delete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            System.debug('SOQL queries before calculateNetAmount: ' + Limits.getQueries());
            // Calcul du montant net des commandes avant l'insertion ou la mise à jour
            OrderHelper.calculateNetAmount(Trigger.new);
            System.debug('SOQL queries after calculateNetAmount: ' + Limits.getQueries());
        }
    }

    if (Trigger.isAfter) {
        Set<Id> accountIds = new Set<Id>();

        if (Trigger.isInsert || Trigger.isUpdate) {
           //  OrderHelper.calculateNetAmount(Trigger.new);
            for (Order o : Trigger.new) {
                accountIds.add(o.AccountId);
            }
        }

        if (Trigger.isDelete) {
            for (Order o : Trigger.old) {
                accountIds.add(o.AccountId);
            }
        }

        if (!accountIds.isEmpty()) {
            System.debug('SOQL queries before updateAccountRevenue: ' + Limits.getQueries());
            // Mise à jour du chiffre d'affaires des comptes
            OrderHelper.updateAccountRevenue(accountIds);
            System.debug('SOQL queries after updateAccountRevenue: ' + Limits.getQueries());
        }
    }
}