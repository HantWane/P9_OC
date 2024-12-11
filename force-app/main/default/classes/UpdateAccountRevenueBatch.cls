public class UpdateAccountRevenueBatch implements Database.Batchable<SObject> {
    private Set<Id> accountIds;

    public UpdateAccountRevenueBatch(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('SOQL queries before start: ' + Limits.getQueries());
        System.debug('Account IDs to process: ' + accountIds);
        Database.QueryLocator queryLocator = Database.getQueryLocator([
            SELECT Id, Chiffre_d_affaire__c
            FROM Account
            WHERE Id IN :accountIds
        ]);
        System.debug('SOQL queries after start: ' + Limits.getQueries());
        return queryLocator;
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('SOQL queries before execute: ' + Limits.getQueries());
        System.debug('Scope size: ' + scope.size());

        List<Account> accountsToUpdate = new List<Account>();
        Set<Id> accountIdsInScope = new Set<Id>();

        for (SObject sObj : scope) {
            accountIdsInScope.add(sObj.Id);
        }

        System.debug('Account IDs in scope: ' + accountIdsInScope);

        // Requête pour obtenir le total des revenus pour chaque compte
        Map<Id, Decimal> accountRevenueMap = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT AccountId, SUM(NetAmount__c) totalRevenue
            FROM Order
            WHERE AccountId IN :accountIdsInScope AND Status = 'Ordered'
            GROUP BY AccountId
        ]) {
            accountRevenueMap.put((Id)ar.get('AccountId'), (Decimal)ar.get('totalRevenue'));
        }

        System.debug('Account Revenue Map: ' + accountRevenueMap);

        for (SObject sObj : scope) {
            Account acc = (Account)sObj;
            Decimal totalRevenue = accountRevenueMap.containsKey(acc.Id) ? accountRevenueMap.get(acc.Id) : 0;
            System.debug('Account Id: ' + acc.Id + ', Initial Chiffre_d_affaire__c: ' + acc.Chiffre_d_affaire__c + ', Calculated Total Revenue: ' + totalRevenue);
            acc.Chiffre_d_affaire__c = totalRevenue;
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            System.debug('Updating accounts: ' + accountsToUpdate);
            update accountsToUpdate;
        }
        System.debug('SOQL queries after execute: ' + Limits.getQueries());
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch finished');
    }
}
