/**
 * Author: Antoine
 * Date: 03/01/2025
 * Description: Trigger on the Order object to handle various operations before and after DML events.
 * 
 * Responsibilities:
 * - Before insert/update: Calculate the net amount for the orders using `OrderService.calculateNetAmount`.
 * - After insert/update/delete: Update the revenue (Chiffre_d_affaire__c) on related accounts using `OrderService.updateAccountRevenue`.
 * 
 * Features:
 * - Handles multiple trigger events (before insert, before update, after insert, after update, after delete).
 * - Ensures that account revenues are recalculated when orders are created, updated, or deleted.
 * - Optimized for bulk processing by leveraging sets to collect Account IDs.
 * 
 * Notes:
 * - The trigger assumes the presence of an `OrderService` class with appropriate methods for calculation and revenue updates.
 * - Proper error handling should be implemented in the service layer to manage exceptions.
 * - Ensure governor limits are respected when working with large datasets.
 */

 trigger OrderTrigger on Order (before insert, before update, after insert, after update, after delete) {

    // Handle operations before DML events (insert/update)
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Calculate net amount for the orders in the current transaction
            OrderService.calculateNetAmount(Trigger.new);
        }
    }

    // Handle operations after DML events (insert/update/delete)
    if (Trigger.isAfter) {
        Set<Id> accountIds = new Set<Id>(); // Collect Account IDs related to orders

        // After insert or update: Collect Account IDs from Trigger.new
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Order o : Trigger.new) {
                accountIds.add(o.AccountId);
            }
        }

        // After delete: Collect Account IDs from Trigger.old
        if (Trigger.isDelete) {
            for (Order o : Trigger.old) {
                accountIds.add(o.AccountId);
            }
        }

        // Update account revenue if Account IDs are collected
        if (!accountIds.isEmpty()) {
            OrderService.updateAccountRevenue(accountIds);
        }
    }
}
