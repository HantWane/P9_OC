/**
 * Author: Antoine
 * Date: 03/01/2025
 * Description: Service class for handling operations related to Orders and Accounts in Salesforce.
 * 
 * Responsibilities:
 * - Calculate the net amount of orders based on their associated order items and shipment costs.
 * - Update the revenue of accounts using a batch process.
 * 
 * Features:
 * - Efficient SOQL queries to minimize governor limits.
 * - Designed to handle bulk operations for scalability and performance.
 * 
 * Note: This class includes helper methods for calculating and updating financial metrics
 *       and integrates with the UpdateAccountRevenueBatch class for batch processing.
 */

public class OrderService {

    // Method to calculate the net amount for a list of orders
    public static void calculateNetAmount(List<Order> newOrders) {
        
        // Collect all order IDs for orders with the status 'Ordered'
        Set<Id> orderIds = new Set<Id>();
        for (Order o : newOrders) {
            if (o.Status == 'Ordered') {
                orderIds.add(o.Id);
            }
        }

        // Perform a single SOQL query to fetch all related OrderItems for the collected orders
        List<OrderItem> orderItems = [
            SELECT OrderId, Quantity, UnitPrice 
            FROM OrderItem 
            WHERE OrderId IN :orderIds
        ];

        // Use a map to associate OrderItems with their corresponding Orders
        Map<Id, List<OrderItem>> orderItemMap = new Map<Id, List<OrderItem>>();
        for (OrderItem item : orderItems) {
            if (!orderItemMap.containsKey(item.OrderId)) {
                orderItemMap.put(item.OrderId, new List<OrderItem>());
            }
            orderItemMap.get(item.OrderId).add(item);
        }

        // Iterate through each order to compute its net amount
        for (Order currentOrder : newOrders) {
            // If the order is not 'Ordered', reset its net amount to null
            if (currentOrder.Status != 'Ordered') {
                currentOrder.NetAmount__c = null;
                continue;
            }

            // Compute the net amount using the associated OrderItems
            computeNetAmount(currentOrder, orderItemMap.get(currentOrder.Id));
        }
    }

    // Method to update account revenue by triggering a batch process
    public static void updateAccountRevenue(Set<Id> accountIds) {

        // Execute the UpdateAccountRevenueBatch for the specified account IDs
        Database.executeBatch(new UpdateAccountRevenueBatch(accountIds));

    }

    // Helper method to compute the net amount for a single order
    @testVisible
    public static void computeNetAmount(Order myOrder, List<OrderItem> items) {
        // Get the shipment cost for the order, defaulting to 0 if null
        Decimal shipmentCost = myOrder.ShipmentCost__c != null ? myOrder.ShipmentCost__c : 0;

        // If no items are associated with the order, set the net amount to the negative shipment cost
        if (items == null || items.isEmpty()) {
            myOrder.NetAmount__c = 0 - shipmentCost;
            return;
        }

        // Calculate the total amount for all order items
        Decimal totalAmount = 0;
        for (OrderItem item : items) {
            totalAmount += item.Quantity * item.UnitPrice;
        }

        // Set the net amount as the total amount minus the shipment cost
        myOrder.NetAmount__c = totalAmount - shipmentCost;
    }
}
