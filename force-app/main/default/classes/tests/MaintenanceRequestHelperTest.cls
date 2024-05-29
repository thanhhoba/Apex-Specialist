@isTest
private class MaintenanceRequestHelperTest {
  @isTest
  static void testPositiveCases() {
    List<Case> closedRequests = MaintenanceRequestFake.createMaintenanceRequestsWithStatusAndType(
      5,
      'Closed',
      'Repair'
    );
    List<Product2> equipments = MaintenanceRequestFake.createEquipments(5);
    List<Equipment_Maintenance_Item__c> maintenanceItems = MaintenanceRequestFake.createEquipmentMaintenanceItems(
      closedRequests,
      equipments
    );

    // Call the method to test
    Test.startTest();
    MaintenanceRequestHelper.createRoutineMaintenanceRequests(closedRequests);
    Test.stopTest();

    // Verify the new requests were created
    List<Case> newRequests = [
      SELECT Id, Type, Status, Vehicle__c
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
  static void testNegativeCases() {
    List<Case> closedRequests = MaintenanceRequestFake.createMaintenanceRequestsWithStatusAndType(
      5,
      'Closed',
      'Repair'
    );
    List<Product2> equipments = MaintenanceRequestFake.createEquipments(5);
    List<Equipment_Maintenance_Item__c> maintenanceItems = MaintenanceRequestFake.createEquipmentMaintenanceItems(
      closedRequests,
      equipments
    );

    // Create maintenance requests for the closed requests
    MaintenanceRequestHelper.createRoutineMaintenanceRequests(closedRequests);

    // Try creating maintenance requests again for the same closed requests
    Test.startTest();
    MaintenanceRequestHelper.createRoutineMaintenanceRequests(closedRequests);
    Test.stopTest();

    List<Case> maintenanceRequests = [
      SELECT Id
      FROM Case
      WHERE Subject = 'Routine Maintenance' AND Status = 'Closed'
    ];

    // Assert that no maintenance requests are created
    System.assertEquals(
      0,
      maintenanceRequests.size(),
      'No maintenance requests should be created'
    );
  }

  @isTest
  static void testBulkCases() {
    // Create a large number of closed request records
    List<Case> closedRequests = MaintenanceRequestFake.createMaintenanceRequestsWithStatusAndType(
      300,
      'Closed',
      'Repair'
    );
    List<Product2> equipments = MaintenanceRequestFake.createEquipments(2);
    List<Equipment_Maintenance_Item__c> maintenanceItems = MaintenanceRequestFake.createEquipmentMaintenanceItems(
      closedRequests,
      equipments
    );

    Test.startTest();
    MaintenanceRequestHelper.createRoutineMaintenanceRequests(closedRequests);
    Test.stopTest();

    List<Case> maintenanceRequests = [
      SELECT Id
      FROM Case
      WHERE Subject = 'Routine Maintenance' AND Status = 'New'
    ];
    System.assertEquals(
      closedRequests.size(),
      maintenanceRequests.size(),
      'Number of maintenance requests should match number of closed requests'
    );
  }
}
