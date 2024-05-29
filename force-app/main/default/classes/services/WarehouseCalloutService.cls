public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {
  public void execute(QueueableContext context) {
    System.debug('WarehouseCalloutService: Starting execute method.');
    // Make callout to external service
    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://th-superbadge-apex.herokuapp.com/equipment');
    req.setMethod('GET');
    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      System.debug(
        'WarehouseCalloutService: Successful callout. Parsing response.'
      );
      // Parse JSON response
      List<Product2> updatedEquipment = parseResponse(res.getBody());
      System.debug(
        'WarehouseCalloutService: Parsed records: ' + updatedEquipment
      );

      // Update Salesforce records
      updateSalesforceRecords(updatedEquipment);
      System.debug('WarehouseCalloutService: Records updated successfully.');
    } else {
      System.debug(
        'WarehouseCalloutService: Callout failed with status code: ' +
        res.getStatusCode()
      );
    }
  }

  private List<Product2> parseResponse(String responseBody) {
    System.debug('WarehouseCalloutService: Parsing response.');
    List<Product2> updatedEquipment = new List<Product2>();
    List<Object> equipmentList = (List<Object>) JSON.deserializeUntyped(
      responseBody
    );

    for (Object obj : equipmentList) {
      Map<String, Object> equipmentMap = (Map<String, Object>) obj;
      Product2 equipment = new Product2();
      equipment.Replacement_Part__c = (Boolean) equipmentMap.get('replacement');
      equipment.Current_Inventory__c = (Decimal) equipmentMap.get('quantity');
      equipment.Name = (String) equipmentMap.get('name');
      equipment.Maintenance_Cycle__c = (Integer) equipmentMap.get(
        'maintenanceperiod'
      );
      equipment.Lifespan_Months__c = (Integer) equipmentMap.get('lifespan');
      equipment.Cost__c = (Decimal) equipmentMap.get('cost');
      equipment.Warehouse_SKU__c = (String) equipmentMap.get('_id');
      //   equipment.Id = (String) equipmentMap.get('_id');

      updatedEquipment.add(equipment);
    }
    System.debug(
      'WarehouseCalloutService: Parsed ' + updatedEquipment.size() + ' records.'
    );
    return updatedEquipment;
  }

  private void updateSalesforceRecords(List<Product2> updatedEquipment) {
    System.debug('WarehouseCalloutService: Updating Salesforce records.');
    // Create a map to store the equipment records with Warehouse_SKU__c as the key
    Map<String, Product2> equipmentMap = new Map<String, Product2>();

    // Populate the map with the updated equipment records
    for (Product2 equip : updatedEquipment) {
      System.debug(
        'Adding to equipmentMap with key: ' + equip.Warehouse_SKU__c
      );
      System.debug('Equip in loop: ' + equip);
      equipmentMap.put(equip.Warehouse_SKU__c, equip);
    }
    System.debug('equipmentMap keys: ' + equipmentMap.keySet());

    // Query existing equipment records from Salesforce based on Warehouse_SKU__c
    List<Product2> existingEquipment = [
      SELECT
        Id,
        Warehouse_SKU__c,
        Replacement_Part__c,
        Cost__c,
        Current_Inventory__c,
        Lifespan_Months__c,
        Maintenance_Cycle__c
      FROM Product2
      WHERE Warehouse_SKU__c IN :equipmentMap.keySet()
    ];

    // Update existing equipment records
    List<Product2> equipmentToUpdate = new List<Product2>();
    for (Product2 existingEquip : existingEquipment) {
      // Retrieve the corresponding updated equipment record from the map
      Product2 updatedEquip = equipmentMap.get(existingEquip.Warehouse_SKU__c);

      // Update the fields of the existing equipment record
      existingEquip.Replacement_Part__c = updatedEquip.Replacement_Part__c;
      existingEquip.Cost__c = updatedEquip.Cost__c;
      existingEquip.Current_Inventory__c = updatedEquip.Current_Inventory__c;
      existingEquip.Lifespan_Months__c = updatedEquip.Lifespan_Months__c;
      existingEquip.Maintenance_Cycle__c = updatedEquip.Maintenance_Cycle__c;

      equipmentToUpdate.add(existingEquip);
    }

    // Perform DML operation to update the equipment records
    if (!equipmentToUpdate.isEmpty()) {
      update equipmentToUpdate;
    }

    // // Insert new equipment records that do not exist in Salesforce
    // List<Product2> equipmentToInsert = new List<Product2>();
    // for (Product2 equip : updatedEquipment) {
    //   if (!existingEquipment.contains(equip)) {
    //     equipmentToInsert.add(equip);
    //   }
    // }
    // if (!equipmentToInsert.isEmpty()) {
    //   insert equipmentToInsert;
    // }

    System.debug('WarehouseCalloutService: Salesforce records updated.');
  }
}
