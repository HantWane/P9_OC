@isTest
private class UpdateAllAccountsTest {

    @isTest
    static void Should_UpdateAllAccountCA_When_OrderIsUpdated() {
        // Step 1: Set up test data - Insert Accounts and related Orders with 'Ordered' status
        
        // Create test Accounts
        Account account1 = new Account(Name = 'Test Account 1');
        Account account2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{ account1, account2 };
        
        // Create test Orders linked to accounts with 'Ordered' status
        Order order1 = new Order(AccountId = account1.Id, Status = 'Ordered', EffectiveDate = Date.today());
        Order order2 = new Order(AccountId = account2.Id, Status = 'Ordered', EffectiveDate = Date.today());
        insert new List<Order>{ order1, order2 };

        // Step 2: Initialize and execute the batch
        Test.startTest();
        
        // Start the batch with a scope size of 100 for limit of DML 
        UpdateAllAccounts batch = new UpdateAllAccounts();
        Database.executeBatch(batch, 100);

        Test.stopTest();
    }
}
