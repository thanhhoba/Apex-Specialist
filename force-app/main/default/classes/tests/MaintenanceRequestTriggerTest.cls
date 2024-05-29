@isTest
private class MaintenanceRequestTriggerTest {
  // static List<Product2> equipments;

  // @testSetup
  // static void setup() {
  //   equipments = MaintenanceRequestMock.createEquipments(5);
  // }
  // If you want to use testSetup(), need to move the insert from Fake to setup so the test methods can receive it

  @isTest
  static void testMaintenanceRequestTriggerWithStatusRepair() {
    List<Case> requests = MaintenanceRequestMock.createMaintenanceRequestsWithStatusAndType(
      5,
      'Open',
      'Repair'
    );
    List<Product2> equipments = MaintenanceRequestMock.createEquipments(5);
    List<Equipment_Maintenance_Item__c> maintenanceItems = MaintenanceRequestMock.createEquipmentMaintenanceItems(
      requests,
      equipments
    );

    for (Case c : requests) {
      c.Status = 'Closed';
    }

    Test.startTest();
    update requests;
    Test.stopTest();

    // Verify that the trigger created new maintenance requests
    List<Case> newRequests = [
      SELECT Id, Type, Status
      FROM Case
      WHERE Type = 'Routine Maintenance' AND Status = 'New'
    ];
    System.assertEquals(
      5,
      newRequests.size(),
      '5 new routine maintenance requests should have been created.'
    );
  }

  @isTest
  static void testMaintenanceRequestTriggerWithStatusRoutineMaintenance() {
    List<Case> requests = MaintenanceRequestMock.createMaintenanceRequestsWithStatusAndType(
      5,
      'Open',
      'Routine Maintenance'
    );
    List<Product2> equipments = MaintenanceRequestMock.createEquipments(5);
    List<Equipment_Maintenance_Item__c> maintenanceItems = MaintenanceRequestMock.createEquipmentMaintenanceItems(
      requests,
      equipments
    );

    for (Case c : requests) {
      c.Status = 'Closed';
    }

    Test.startTest();
    update requests;
    Test.stopTest();

    // Verify that the trigger created new maintenance requests
    List<Case> newRequests = [
      SELECT Id, Type, Status
      FROM Case
      WHERE Type = 'Routine Maintenance' AND Status = 'New'
    ];
    System.assertEquals(
      5,
      newRequests.size(),
      '5 new routine maintenance requests should have been created.'
    );

    // Verify that the maintenance items were retrieved correctly
    Set<Id> maintenanceRequestIds = new Set<Id>();
    for (Case c : requests) {
      maintenanceRequestIds.add(c.Id);
    }

    List<Equipment_Maintenance_Item__c> equipmentMaintenanceItems = [
      SELECT Equipment__c, Maintenance_Request__c
      FROM Equipment_Maintenance_Item__c
      WHERE Maintenance_Request__c IN :maintenanceRequestIds
    ];

    System.assertEquals(
      25,
      equipmentMaintenanceItems.size(),
      '25 maintenance items should have been retrieved.'
    );
  }
}
