public class UpdateAccountRevenueBatch implements Database.Batchable<SObject> {
    private Set<Id> accountIds;

    public UpdateAccountRevenueBatch(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, (SELECT NetAmount__c FROM Orders WHERE Status = 'Ordered')
            FROM Account
            WHERE Id IN :accountIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : (List<Account>)scope) {
            Decimal totalRevenue = 0;

            for (Order o : acc.Orders) {
                totalRevenue += (o.NetAmount__c != null ? o.NetAmount__c : 0);
            }

            acc.Chiffre_d_affaire__c = totalRevenue;
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
