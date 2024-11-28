public class UpdateAccountCAHandler {

        // Méthode pour gérer l'insertion des commandes
    public static void handleAfterInsert(List<Order> orders) {
        Set<Id> accountIds = new Set<Id>();

        // Collecter tous les Ids des comptes associés aux commandes insérées
        for (Order order : orders) {
            accountIds.add(order.AccountId);
        }

        // Récupérer les comptes associés pour mettre à jour le chiffre d'affaires
        List<Account> accountsToUpdate = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id IN :accountIds];

        for (Account acc : accountsToUpdate) {
            Decimal totalAmount = 0;

            // Calculer le chiffre d'affaires total en fonction des commandes associées
            for (Order order : orders) {
                if (order.AccountId == acc.Id) {
                    totalAmount += order.TotalAmount;
                }
            }

            // Mettre à jour le chiffre d'affaires du compte
            acc.Chiffre_d_affaire__c += totalAmount;
        }

        // Mettre à jour les comptes
        update accountsToUpdate;
    }

    // Méthode pour gérer la mise à jour des commandes
    public static void handleAfterUpdate(List<Order> orders) {
        Set<Id> accountIds = new Set<Id>();

        // Collecter tous les Ids des comptes associés aux commandes mises à jour
        for (Order order : orders) {
            accountIds.add(order.AccountId);
        }

        // Récupérer les comptes associés pour mettre à jour le chiffre d'affaires
        List<Account> accountsToUpdate = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id IN :accountIds];

        for (Account acc : accountsToUpdate) {
            Decimal totalAmount = 0;

            // Calculer le chiffre d'affaires total en fonction des commandes associées
            for (Order order : orders) {
                if (order.AccountId == acc.Id) {
                    totalAmount += order.TotalAmount;
                }
            }

            // Mettre à jour le chiffre d'affaires du compte
            acc.Chiffre_d_affaire__c += totalAmount;
        }

        // Mettre à jour les comptes
        update accountsToUpdate;
    }
}
