public class ScheduleUpdateAccountRevenue implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Récupérer les IDs des comptes à mettre à jour
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : [SELECT Id FROM Account WHERE Chiffre_d_affaire__c != NULL]) {
            accountIds.add(acc.Id);
        }

        // Créer une instance du batch et l'exécuter
        UpdateAccountRevenueBatch batch = new UpdateAccountRevenueBatch(accountIds);
        Database.executeBatch(batch);
    }
}
