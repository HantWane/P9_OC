/**
 * Trigger: OrderTrigger
 * 
 * Trigger on the Order object to handle operations before and after DML events.
 * 
 * Responsibilities:
 *   Before insert/update: Calculates the net amount for the orders using {@link OrderService#calculateNetAmount(List)}.
 *   After insert/update/delete: Updates the revenue (Chiffre_d_affaire__c) on related accounts using {@link OrderService#updateAccountRevenue(Set)}.
 * 
 * Features:
 *   Handles multiple trigger events: <code>before insert</code>, <code>before update</code>, <code>after insert</code>, <code>after update</code>, <code>after delete</code>.
 *   Ensures account revenues are recalculated when orders are created, updated, or deleted.
 *   Optimized for bulk processing by leveraging <code>Set</code> to collect Account IDs.
 * 
 * Notes:
 
 *   This trigger depends on the {@link OrderService} class for business logic.
 *   Ensure proper error handling is implemented in the service layer to manage exceptions
 *   Governor limits are respected by optimizing operations for bulk processing.
 *   This trigger is designed to handle updates on related OrderItem records (code not included).

 * 
 * @author Antoine
 * @since 03/01/2025
 */
trigger OrderTrigger on Order (before insert, before update, after insert, after update, after delete) {

    /**
     * Handles operations before DML events (insert/update).
     *   Calculates the net amount for the orders in the current transaction.
     */
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Calculate net amount for the orders
            OrderService.calculateNetAmount(Trigger.new);
        }
    }

    /**
     * Handles operations after DML events (insert/update/delete).
     *   Collects Account IDs associated with orders.
     *   Updates account revenue based on the collected Account IDs.
     */
    if (Trigger.isAfter) {
        // Collect Account IDs from Trigger.new for insert/update events
        if (Trigger.isInsert || Trigger.isUpdate) {
            OrderService.updateAccountRevenue(Trigger.new);
        }

        // Collect Account IDs from Trigger.old for delete events
        if (Trigger.isDelete) {
            OrderService.updateAccountRevenue(Trigger.old);
        }
    }
}
