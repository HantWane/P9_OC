global class UpdateAccountRevenueBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all accounts
        return Database.getQueryLocator([SELECT Id, (SELECT TotalAmount FROM Orders) FROM Account]);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        // Map to store the total amount for each account
        Map<Id, Decimal> accountTotalAmountMap = new Map<Id, Decimal>();

        // Iterate over the accounts and their related orders
        for (Account acc : scope) {
            Decimal totalAmount = 0;
            for (Order ord : acc.Orders) {
                totalAmount += ord.TotalAmount;
            }
            accountTotalAmountMap.put(acc.Id, totalAmount);
        }

        // Update the Chiffre_d_affaire__c field for each account
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accountId : accountTotalAmountMap.keySet()) {
            Account acc = new Account(Id = accountId, Chiffre_d_affaire__c = accountTotalAmountMap.get(accountId));
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}
