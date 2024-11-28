trigger UpdateAccountCA on Order (after update) {
    Set<Id> accountIds = new Set<Id>();
    for (Order o : Trigger.new) {
        if (o.AccountId != null && o.Status == 'Ordered') {
            accountIds.add(o.AccountId);
        }
    }

    if (!accountIds.isEmpty()) {
        // Appel d'une méthode pour mettre à jour les comptes
        OrderHelper.updateAccountRevenue(accountIds);
    }
}