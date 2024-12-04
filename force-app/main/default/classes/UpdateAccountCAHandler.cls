public class UpdateAccountCAHandler {

    // Méthode pour gérer l'insertion des commandes
    public static void handleAfterInsert(List<Order> orders) {
        System.debug('Handling after insert for orders: ' + orders);
        updateAccountRevenue(orders);
    }

    // Méthode pour gérer la mise à jour des commandes
    public static void handleAfterUpdate(List<Order> orders) {
        System.debug('Handling after update for orders: ' + orders);
        updateAccountRevenue(orders);
    }

    // Méthode pour gérer la suppression des commandes
    public static void handleAfterDelete(List<Order> deletedOrders) {
        System.debug('Handling after delete for orders: ' + deletedOrders);
        Set<Id> accountIds = new Set<Id>();

        // Collecter tous les Ids des comptes associés aux commandes supprimées
        for (Order order : deletedOrders) {
            accountIds.add(order.AccountId);
        }

        // Récupérer les comptes associés pour mettre à jour le chiffre d'affaires
        List<Account> accountsToUpdate = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id IN :accountIds];

        for (Account acc : accountsToUpdate) {
            Decimal totalAmount = 0;

            // Recalculer le chiffre d'affaires avec les commandes restantes
            List<Order> remainingOrders = [SELECT TotalAmount FROM Order WHERE AccountId = :acc.Id];
            for (Order remainingOrder : remainingOrders) {
                totalAmount += remainingOrder.TotalAmount;
            }

            // Si aucune commande restante, le chiffre d'affaires est défini à 0
            acc.Chiffre_d_affaire__c = totalAmount;
            System.debug('Updating account ' + acc.Id + ' with totalAmount: ' + totalAmount);
        }

        // Mettre à jour les comptes
        update accountsToUpdate;
    }

    // Méthode partagée pour gérer les insertions et mises à jour
    private static void updateAccountRevenue(List<Order> orders) {
        System.debug('Updating account revenue for orders: ' + orders);
        Set<Id> accountIds = new Set<Id>();

        // Collecter tous les Ids des comptes associés aux commandes
        for (Order order : orders) {
            accountIds.add(order.AccountId);
        }

        // Récupérer les comptes associés pour mettre à jour le chiffre d'affaires
        List<Account> accountsToUpdate = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id IN :accountIds];

        for (Account acc : accountsToUpdate) {
            Decimal totalAmount = 0;

            // Calculer le chiffre d'affaires total en fonction des commandes associées
            List<Order> relatedOrders = [SELECT TotalAmount FROM Order WHERE AccountId = :acc.Id];
            for (Order relatedOrder : relatedOrders) {
                totalAmount += relatedOrder.TotalAmount;
            }

            // Mettre à jour le chiffre d'affaires avec une valeur par défaut de 0 si nécessaire
            acc.Chiffre_d_affaire__c = totalAmount == null ? 0 : totalAmount;
            System.debug('Updating account ' + acc.Id + ' with totalAmount: ' + totalAmount);
        }

        // Mettre à jour les comptes
        update accountsToUpdate;
    }
}
