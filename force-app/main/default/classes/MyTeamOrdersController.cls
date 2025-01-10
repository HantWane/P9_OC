/**
 * Author: Antoine
 * Date: 03/01/2025
 * 
 * Description:
 * This class is responsible for calculating the sum of orders assigned to the 
 * current user's team based on the user's role. It filters the orders with a 
 * status of 'Ordered' and ensures that only the orders related to the 
 * current user's account are included in the sum.
 * 
 * Public Methods:
 * - SumOrders: Retrieves the total of 'TotalAmount' for all 'Ordered' orders 
 *   associated with the current user's accounts. The sum is filtered based 
 *   on the current user's role and ownership of the account.
 * 
 * Features:
 * - Uses aggregate SOQL query to calculate the sum of 'TotalAmount' from the 
 *   'Order' object for the user’s owned accounts.
 * - Accounts are filtered by the 'OwnerId' matching the current user's ID.
 * - The method ensures that the sum of the orders is properly handled even if 
 *   no orders are found, returning a default value of 0 in such cases.
 * 
 * Notes:
 * - Assumes the user has an associated role and owns at least one account.
 * - The class is defined with `with sharing`
 */


 public with sharing class MyTeamOrdersController {
    public decimal SumOrders {
        get {
            // Récupérer l'ID de l'utilisateur connecté
            Id userId = UserInfo.getUserId();

            // Récupérer le rôle de l'utilisateur connecté
            UserRole userRole = [SELECT Id, Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId()];

            // Filtrer les commandes par rôle de l'utilisateur connecté
            AggregateResult groupedResults = [SELECT SUM(TotalAmount) total
                                              FROM Order
                                              WHERE Status = 'Ordered'
                                              AND Account.Owner.UserRoleId = :userRole.Id];

            return groupedResults.get('total') != null ? (decimal)groupedResults.get('total') : 0;
        }
        set;
    }
}
