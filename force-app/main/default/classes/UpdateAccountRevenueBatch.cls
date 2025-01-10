/**
 * Batchable class to update the revenue (Chiffre d'affaires) of Accounts based on their related Orders.
 * 
 * Responsibilities:
 * - Retrieve Accounts and their associated Orders using a SOQL query.
 * - Calculate the total revenue for each Account by summing up the TotalAmount of its Orders.
 * - Update the `Chiffre_d_affaire__c` field on the Account object.
 * 
 * Features:
 * - Uses `Database.Batchable` for processing large volumes of data efficiently.
 * - Designed to respect Salesforce governor limits by processing records in manageable batches.
 * - Flexible: Accepts a set of Account IDs for targeted processing.
 * 
 * Notes:
 * - Ensure that the `Chiffre_d_affaire__c` field is available and writable on the Account object.
 * - Ideal for periodic updates or large-scale recalculations of revenue metrics.
 * 
 * Author: Antoine
 * Date: 03/01/2025
 */
global class UpdateAccountRevenueBatch implements Database.Batchable<sObject> {

    /**
     * A set to store the IDs of the accounts to be processed.
     */
    private Set<Id> accountIds;

    /**
     * Constructor to initialize the batch with the specific account IDs.
     * 
     * @param accountIds Set of Account IDs to process in the batch.
     */
    global UpdateAccountRevenueBatch(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    /**
     * Defines the query to retrieve the data to be processed in batches.
     * 
     * @param BC The `BatchableContext` object that represents the batch execution context.
     * @return A `Database.QueryLocator` that retrieves the Accounts and their related Orders.
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, (SELECT TotalAmount FROM Orders) 
            FROM Account 
            WHERE Id IN :accountIds
        ]);
    }

    /**
     * Processes each batch of Accounts retrieved in the start method.
     * 
     * Responsibilities:
     * - Iterates through each Account in the current batch.
     * - Calculates the total revenue by summing the `TotalAmount` of related Orders.
     * - Updates the `Chiffre_d_affaire__c` field for each Account.
     * 
     * @param BC The `BatchableContext` object that represents the batch execution context.
     * @param scope A list of `Account` objects to process in the current batch.
     */
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : scope) {
            Decimal totalAmount = 0;

            // Calculate total revenue for the account
            for (Order ord : acc.Orders) {
                totalAmount += ord.TotalAmount;
            }

            acc.Chiffre_d_affaire__c = totalAmount;
            accountsToUpdate.add(acc);
        }

        // Update accounts in bulk
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    /**
     * Called after all batches are processed.
     * 
     * Responsibilities:
     * - Can be used for logging or post-processing tasks.
     * - Currently no implementation provided.
     * 
     * @param BC The `BatchableContext` object that represents the batch execution context.
     */
    global void finish(Database.BatchableContext BC) {
        // No implementation
    }
}
