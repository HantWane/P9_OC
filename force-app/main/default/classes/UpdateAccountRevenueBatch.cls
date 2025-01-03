/**
 * Author: Antoine
 * Date: 03/01/2025
 * Description: Batchable class to update the revenue (Chiffre d'affaires) of Accounts based on their related Orders.
 * 
 * Responsibilities:
 * - Retrieve Accounts and their associated Orders using a SOQL query.
 * - Calculate the total revenue for each Account by summing up the TotalAmount of its Orders.
 * - Update the Chiffre_d_affaire__c field on the Account object.
 * 
 * Features:
 * - Uses Database.Batchable for processing large volumes of data efficiently.
 * - Designed to respect Salesforce governor limits by processing records in manageable batches.
 * - Flexible: Accepts a set of Account IDs for targeted processing.
 * 
 * Note: Ensure that the Chiffre_d_affaire__c field is available and writable on the Account object.
 */

global class UpdateAccountRevenueBatch implements Database.Batchable<sObject> {

    // A set to store the IDs of the accounts to be processed
    private Set<Id> accountIds;

    // Constructor to initialize the batch with the specific account IDs
    global UpdateAccountRevenueBatch(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    // The start method defines the query to retrieve the data to be processed in batches
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query to fetch accounts along with their related orders for the given account IDs
        return Database.getQueryLocator([
            SELECT Id, (SELECT TotalAmount FROM Orders) FROM Account WHERE Id IN :accountIds
        ]);
    }

    // The execute method processes each batch of accounts retrieved in the start method
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        // List to store accounts that need to be updated
        List<Account> accountsToUpdate = new List<Account>();

        // Iterate through each account in the batch
        for (Account acc : scope) {
            // Initialize a variable to calculate the total order amount
            Decimal totalAmount = 0;

            // Sum up the TotalAmount of all related orders for the current account
            for (Order ord : acc.Orders) {
                totalAmount += ord.TotalAmount;
            }

            // Assign the calculated total to the custom field 'Chiffre_d_affaire__c'
            acc.Chiffre_d_affaire__c = totalAmount;

            // Add the account to the list of accounts to be updated
            accountsToUpdate.add(acc);
        }

        // Update accounts if there are any changes to be saved
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    // The finish method is called after all batches are processed
    global void finish(Database.BatchableContext BC) {
    }
}
