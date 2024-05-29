@isTest
private class WarehouseCalloutServiceTest {
  @isTest
  static void testWarehouseCalloutService() {
    List<Product2> products = MaintenanceRequestMock.createEquipments(2);
    Set<String> setIds = new Set<String>();

    for (Product2 product : products) {
      setIds.add(product.Warehouse_SKU__c);
    }

    // Set the mock callout
    Test.setMock(
      HttpCalloutMock.class,
      new WarehouseCalloutServiceMock(setIds)
    );

    // Start the test
    Test.startTest();
    WarehouseCalloutService job = new WarehouseCalloutService();
    System.enqueueJob(job);
    Test.stopTest();

    // Verify that the records were created or updated correctly
    List<Product2> productsOutput = [
      SELECT
        Id,
        Name,
        Replacement_Part__c,
        Cost__c,
        Current_Inventory__c,
        Lifespan_Months__c,
        Maintenance_Cycle__c,
        Warehouse_SKU__c
      FROM Product2
      WHERE Warehouse_SKU__c IN :setIds
    ];

    System.assertEquals(
      2,
      productsOutput.size(),
      'Expected 2 products to be created or updated.'
    );
  }
}
