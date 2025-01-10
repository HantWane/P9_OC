/**
 * Author: Antoine
 * Date: 03/01/2025
 * 
 * Description:
 * Utility class for creating Salesforce records such as Accounts, Products, 
 * Orders, and Order Items. This class is designed for use in test contexts 
 * or as a data factory for bulk operations, facilitating the creation and 
 * insertion of records for testing purposes.
 * 
 * Features:
 * - Provides methods for creating and inserting standard Salesforce records 
 *   including Account, Product2, PricebookEntry, Order, and OrderItem.
 * - Each method automatically inserts the created record(s) into the Salesforce 
 *   database.
 * - Designed to be used within test classes for creating mock data or for bulk 
 *   operations in a controlled environment.
 * 
 * Notes:
 * - This class is implemented with sharing to respect the current user's 
 *   sharing rules.
 * 
 * Public Methods:
 * - createAccount: Creates and inserts an Account record with the given 
 *   account name.
 * - createProduct: Creates and inserts a Product2 record with the given 
 *   product name, and marks it as active.
 * - createPriceBookEntry: Creates and inserts a PricebookEntry record for 
 *   the given Product2 ID and unit price.
 * - createOrder: Creates and inserts a single Order record with the specified 
 *   account, status, effective date, and shipment cost.
 * - createOrders: Creates and inserts multiple Order records based on the 
 *   specified account, number of orders, status, effective date, and shipment 
 *   cost.
 * - createOrderItems: Creates and inserts multiple OrderItem records for the 
 *   given orders and associated product/pricebook data.
 * 
 */

 @isTest
 public with sharing class DataFactory {
 
     // Creates and inserts an Account record with the given name
     public static Account createAccount(String accountName) {
         Account acc = new Account(Name = accountName);
         insert acc;
         return acc;
     }
 
     // Creates and inserts a Product2 record with the given name and sets it as active
     public static Product2 createProduct(String productName) {
         Product2 prod = new Product2(Name = productName, IsActive = true);
         insert prod;
         return prod;
     }
 
     // Creates and inserts a PricebookEntry record for the given Product2 ID and unit price
     public static PricebookEntry createPriceBookEntry(Id product2Id, Double unitPrice) {
         PricebookEntry pricebookEntry = new PricebookEntry(
             Pricebook2Id = Test.getStandardPricebookId(),
             Product2Id = product2Id,
             UnitPrice = unitPrice,
             IsActive = true
         );
         insert pricebookEntry;
         return pricebookEntry;
     }
 
     // Creates and inserts Order records with the specified details
     public static List<Order> createOrders(Id accountId, String status, Date effectiveDate, Decimal shipmentCost, Integer numberOfOrders) {
         List<Order> ordersList = new List<Order>();
         for (Integer i = 0; i < numberOfOrders; i++) {
             Order order = new Order(
                 AccountId = accountId,
                 Status = status,
                 EffectiveDate = effectiveDate,
                 ShipmentCost__c = shipmentCost,
                 Pricebook2Id = Test.getStandardPricebookId()
             );
             ordersList.add(order);
         }
         insert ordersList;
         return ordersList;
     }
 
     // Overloaded method to create a single Order record
     public static Order createOrder(Id accountId, String status, Date effectiveDate, Decimal shipmentCost) {
         List<Order> ordersList = createOrders(accountId, status, effectiveDate, shipmentCost, 1);
         return ordersList[0];
     }
 
     // Creates and inserts OrderItem records for the given orders and associated product/pricebook data
     public static List<OrderItem> createOrderItems(List<Order> ordersList, Map<String, Id> orderData, Decimal unitPrice) {
         List<OrderItem> orderItems = new List<OrderItem>();
         for (Order order : ordersList) {
             OrderItem orderItem = new OrderItem(
                 OrderId = order.Id,
                 Product2Id = orderData.get('Product2Id'),
                 PricebookEntryId = orderData.get('PricebookEntryId'),
                 Quantity = 1,
                 UnitPrice = unitPrice
             );
             orderItems.add(orderItem);
         }
         insert orderItems;
         return orderItems;
     }
 }
 
