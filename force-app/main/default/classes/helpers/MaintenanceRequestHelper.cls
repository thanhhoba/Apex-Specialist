public with sharing class MaintenanceRequestHelper {
  public static void createRoutineMaintenanceRequests(
    List<Case> closedRequests
  ) {
    Integer batchSize = 10;
    for (Integer i = 0; i < closedRequests.size(); i += batchSize) {
      Integer endIndex = Math.min(i + batchSize, closedRequests.size());
      List<Case> batch = new List<Case>();
      for (Integer j = i; j < endIndex; j++) {
        batch.add(closedRequests[j]);
      }
      processBatch(batch);
    }
  }

  public static void processBatch(List<Case> closedRequests) {
    Set<Id> maintenanceRequestIds = collectMaintenanceRequestIds(
      closedRequests
    );
    List<Equipment_Maintenance_Item__c> maintenanceItems = getMaintenanceItems(
      maintenanceRequestIds
    );

    Map<Id, Vehicle__c> vehicleMap = getVehicles(closedRequests);
    Map<Id, Product2> equipmentMap = getEquipments(maintenanceItems);

    List<Case> newRequests = createNewRequests(
      closedRequests,
      vehicleMap,
      equipmentMap,
      maintenanceItems
    );
    insertNewRequests(newRequests);

    List<Equipment_Maintenance_Item__c> newEMIs = createNewEMIs(
      newRequests,
      maintenanceItems
    );
    insertNewEMIs(newEMIs);
  }

  //Get Collects the IDs of the closed maintenance requests
  private static Set<Id> collectMaintenanceRequestIds(
    List<Case> closedRequests
  ) {
    Set<Id> maintenanceRequestIds = new Set<Id>();
    for (Case closedRequest : closedRequests) {
      maintenanceRequestIds.add(closedRequest.Id);
    }
    return maintenanceRequestIds;
  }

  // Retrieves a list of equipment maintenance items based on the collected maintenance request IDs
  private static List<Equipment_Maintenance_Item__c> getMaintenanceItems(
    Set<Id> maintenanceRequestIds
  ) {
    return new List<Equipment_Maintenance_Item__c>(
      [
        SELECT Equipment__c, Maintenance_Request__c
        FROM Equipment_Maintenance_Item__c
        WHERE Maintenance_Request__c IN :maintenanceRequestIds
      ]
    );
  }

  // Fetches a map of vehicle records associated with the closed maintenance requests
  private static Map<Id, Vehicle__c> getVehicles(List<Case> closedRequests) {
    Set<Id> vehicleIds = new Set<Id>();
    for (Case closedRequest : closedRequests) {
      vehicleIds.add(closedRequest.Vehicle__c);
    }
    return new Map<Id, Vehicle__c>(
      [SELECT Id FROM Vehicle__c WHERE Id IN :vehicleIds]
    );
  }

  // Retrieves a map of equipment records associated with the maintenance items
  private static Map<Id, Product2> getEquipments(
    List<Equipment_Maintenance_Item__c> maintenanceItems
  ) {
    Set<Id> equipmentIds = new Set<Id>();
    for (Equipment_Maintenance_Item__c emi : maintenanceItems) {
      equipmentIds.add(emi.Equipment__c);
    }
    return new Map<Id, Product2>(
      [SELECT Id, Maintenance_Cycle__c FROM Product2 WHERE Id IN :equipmentIds]
    );
  }

  // Creates new maintenance request records based on the data collected from the previous methods
  private static List<Case> createNewRequests(
    List<Case> closedRequests,
    Map<Id, Vehicle__c> vehicleMap,
    Map<Id, Product2> equipmentMap,
    List<Equipment_Maintenance_Item__c> maintenanceItems
  ) {
    List<Case> newRequests = new List<Case>();
    for (Case closedRequest : closedRequests) {
      Vehicle__c vehicle = vehicleMap.get(closedRequest.Vehicle__c);
      if (vehicle != null) {
        Date newDueDate = calculateDueDate(
          closedRequest.Id,
          equipmentMap,
          maintenanceItems
        );
        if (newDueDate != null) {
          newRequests.add(
            createNewMaintenanceRequest(closedRequest, newDueDate)
          );
        }
      }
    }
    return newRequests;
  }

  private static void insertNewRequests(List<Case> newRequests) {
    if (Schema.sObjectType.Case.isCreateable() && !newRequests.isEmpty()) {
      insert newRequests;
    }
  }

  // Creates new equipment maintenance item records for the newly created maintenance requests
  private static List<Equipment_Maintenance_Item__c> createNewEMIs(
    List<Case> newRequests,
    List<Equipment_Maintenance_Item__c> maintenanceItems
  ) {
    List<Equipment_Maintenance_Item__c> newEMIs = new List<Equipment_Maintenance_Item__c>();
    for (Case newRequest : newRequests) {
      newEMIs.addAll(
        createEquipmentMaintenanceItems(newRequest.Id, maintenanceItems)
      );
    }
    return newEMIs;
  }

  private static void insertNewEMIs(
    List<Equipment_Maintenance_Item__c> newEMIs
  ) {
    if (
      Schema.sObjectType.Equipment_Maintenance_Item__c.isCreateable() &&
      !newEMIs.isEmpty()
    ) {
      insert newEMIs;
    }
  }

  // The function calculates the expiration date for a new maintenance request
  private static Date calculateDueDate(
    Id closedRequestId,
    Map<Id, Product2> equipmentMap,
    List<Equipment_Maintenance_Item__c> maintenanceItems
  ) {
    Date newDueDate = null;

    // Calculate expiration date using the shortest maintenance cycle
    for (Equipment_Maintenance_Item__c emi : maintenanceItems) {
      if (emi.Maintenance_Request__c == closedRequestId) {
        Product2 equipment = equipmentMap.get(emi.Equipment__c);
        if (equipment != null && equipment.Maintenance_Cycle__c != null) {
          Date equipmentDueDate = Date.today()
            .addDays(equipment.Maintenance_Cycle__c.intValue());
          if (newDueDate == null || equipmentDueDate < newDueDate) {
            newDueDate = equipmentDueDate;
          }
        }
      }
    }

    return newDueDate;
  }

  private static Case createNewMaintenanceRequest(
    Case closedRequest,
    Date newDueDate
  ) {
    Case newRequest = new Case();
    newRequest.Subject = 'Routine Maintenance';
    newRequest.Type = 'Routine Maintenance';
    newRequest.Status = 'New';
    newRequest.Vehicle__c = closedRequest.Vehicle__c;
    newRequest.Origin = 'Automated';
    newRequest.Date_Reported__c = Date.today();
    newRequest.Date_Due__c = newDueDate;
    return newRequest;
  }

  private static List<Equipment_Maintenance_Item__c> createEquipmentMaintenanceItems(
    Id newRequestId,
    List<Equipment_Maintenance_Item__c> maintenanceItems
  ) {
    List<Equipment_Maintenance_Item__c> newEMIs = new List<Equipment_Maintenance_Item__c>();

    for (Equipment_Maintenance_Item__c emi : maintenanceItems) {
      if (emi.Maintenance_Request__c != null) {
        Equipment_Maintenance_Item__c newEmi = new Equipment_Maintenance_Item__c();
        newEmi.Equipment__c = emi.Equipment__c;
        newEmi.Maintenance_Request__c = newRequestId;
        newEMIs.add(newEmi);
      }
    }

    return newEMIs;
  }
}
