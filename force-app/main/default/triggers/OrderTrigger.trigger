/**
 * Trigger: OrderTrigger
 * 
 * Trigger on the Order object to handle operations before and after DML events.
 * 
 * <p><b>Responsibilities:</b></p>
 * <ul>
 *   <li><b>Before insert/update:</b> Calculates the net amount for the orders using {@link OrderService#calculateNetAmount(List)}.</li>
 *   <li><b>After insert/update/delete:</b> Updates the revenue (Chiffre_d_affaire__c) on related accounts using {@link OrderService#updateAccountRevenue(Set)}.</li>
 * </ul>
 * 
 * <p><b>Features:</b></p>
 * <ul>
 *   <li>Handles multiple trigger events: <code>before insert</code>, <code>before update</code>, <code>after insert</code>, <code>after update</code>, <code>after delete</code>.</li>
 *   <li>Ensures account revenues are recalculated when orders are created, updated, or deleted.</li>
 *   <li>Optimized for bulk processing by leveraging <code>Set</code> to collect Account IDs.</li>
 * </ul>
 * 
 * <p><b>Notes:</b></p>
 * <ul>
 *   <li>This trigger depends on the {@link OrderService} class for business logic.</li>
 *   <li>Ensure proper error handling is implemented in the service layer to manage exceptions.</li>
 *   <li>Governor limits are respected by optimizing operations for bulk processing.</li>
 *   <li>This trigger is designed to handle updates on related OrderItem records (code not included).</li>
 * </ul>
 * 
 * @author Antoine
 * @since 03/01/2025
 */
trigger OrderTrigger on Order (before insert, before update, after insert, after update, after delete) {

    /**
     * Handles operations before DML events (insert/update).
     * <ul>
     *   <li>Calculates the net amount for the orders in the current transaction.</li>
     * </ul>
     */
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Calculate net amount for the orders
            OrderService.calculateNetAmount(Trigger.new);
        }
    }

    /**
     * Handles operations after DML events (insert/update/delete).
     * <ul>
     *   <li>Collects Account IDs associated with orders.</li>
     *   <li>Updates account revenue based on the collected Account IDs.</li>
     * </ul>
     */
    if (Trigger.isAfter) {
        Set<Id> accountIds = new Set<Id>();

        // Collect Account IDs from Trigger.new for insert/update events
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Order o : Trigger.new) {
                accountIds.add(o.AccountId);
            }
        }

        // Collect Account IDs from Trigger.old for delete events
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
