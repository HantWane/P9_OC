public without sharing class MyTeamOrdersController {
    public decimal SumOrders {
        get {
            // Récupérer l'ID de l'utilisateur connecté
            Id userId = UserInfo.getUserId();

            // Récupérer le rôle de l'utilisateur connecté
            UserRole userRole = [SELECT Id, Name FROM UserRole WHERE Id IN (SELECT UserRoleId FROM User WHERE Id = :userId)];

            // Définir les rôles des équipes
            Set<String> teamRoles = new Set<String>{'Eastern Sales Team', 'Western Sales Team'};

            // Vérifier si le rôle de l'utilisateur est dans les rôles des équipes
            if (teamRoles.contains(userRole.Name)) {
                // Récupérer les IDs des comptes associés au rôle de l'utilisateur
                Set<Id> accountIds = new Set<Id>();
                for (Account acc : [SELECT Id FROM Account WHERE Owner.UserRole.Name = :userRole.Name]) {
                    accountIds.add(acc.Id);
                }

                // Filtrer les commandes en fonction des comptes associés au rôle de l'utilisateur
                AggregateResult groupedResults = [SELECT SUM(TotalAmount) total FROM Order WHERE AccountId IN :accountIds];
                if (groupedResults.get('total') != null) {
                    return (decimal)groupedResults.get('total');
                } else {
                    return 0;
                }
            } else {
                // Si le rôle de l'utilisateur n'est pas dans les rôles des équipes, retourner 0
                return 0;
            }
        }
        set;
    }
}
