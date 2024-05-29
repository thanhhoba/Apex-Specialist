@isTest
public class MaintenanceRequestMock {
  public static List<Case> createMaintenanceRequestsWithStatusAndType(
    Integer numRecords,
    String status,
    String type
  ) {
    List<Case> maintainRequests = new List<Case>();
    List<Vehicle__c> vehicles = createVehicles(numRecords);

    for (Integer i = 0; i < numRecords; i++) {
      Case maintainRequest = new Case();
      maintainRequest.Status = status;
      maintainRequest.Subject = 'Subject Test' + i;
      maintainRequest.Type = type;
      maintainRequest.Vehicle__c = vehicles[i].Id;

      maintainRequests.add(maintainRequest);
    }
    insert maintainRequests;
    return maintainRequests;
  }

  public static List<Vehicle__c> createVehicles(Integer numRecords) {
    List<Vehicle__c> vehicles = new List<Vehicle__c>();
    for (Integer i = 0; i < numRecords; i++) {
      Vehicle__c vehicle = new Vehicle__c();
      vehicle.Name = 'Vehicle Test' + i;

      vehicles.add(vehicle);
    }
    insert vehicles;
    return vehicles;
  }

  public static List<Product2> createEquipments(Integer numRecords) {
    List<Product2> equipments = new List<Product2>();
    Integer count = 1;
    for (Integer i = 0; i < numRecords; i++) {
      equipments.add(
        new Product2(
          Name = 'Equipment Test' + i,
          Maintenance_Cycle__c = 150,
          Lifespan_Months__c = 30,
          Replacement_Part__c = true,
          Warehouse_SKU__c = '55d66xxxxxxxxxx74' + count++
        )
      );
    }
    insert equipments;
    return equipments;
  }

  public static List<Equipment_Maintenance_Item__c> createEquipmentMaintenanceItems(
    List<Case> maintainRequests,
    List<Product2> equipments
  ) {
    List<Equipment_Maintenance_Item__c> maintenanceItems = new List<Equipment_Maintenance_Item__c>();
    for (Case c : maintainRequests) {
      for (Product2 p : equipments) {
        Equipment_Maintenance_Item__c newEmi = new Equipment_Maintenance_Item__c();
        newEmi.Equipment__c = p.Id;
        newEmi.Maintenance_Request__c = c.Id;

        maintenanceItems.add(newEmi);
      }
    }
    insert maintenanceItems;
    return maintenanceItems;
  }
}
