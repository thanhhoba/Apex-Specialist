@isTest
global class WarehouseCalloutServiceMock implements HttpCalloutMock {
  private Set<String> setIds;

  // Constructor to accept the set of IDs
  global WarehouseCalloutServiceMock(Set<String> setIds) {
    this.setIds = setIds;
  }

  global HttpResponse respond(HttpRequest request) {
    HttpResponse response = new HttpResponse();
    response.setHeader('Content-Type', 'application/json');

    // Construct the JSON response body
    List<Map<String, Object>> responseBody = new List<Map<String, Object>>();
    for (String id : setIds) {
      Integer intSku = 1000;
      Map<String, Object> equipmentData = new Map<String, Object>{
        '_id' => id,
        'replacement' => true,
        'quantity' => 5,
        'name' => 'Product ' + id,
        'maintenanceperiod' => 365,
        'lifespan' => 0,
        'cost' => 10000,
        'sku' => String.valueOf(intSku++)
      };
      responseBody.add(equipmentData);
    }

    // // Convert the response body to JSON
    response.setBody(JSON.serialize(responseBody));
    response.setStatusCode(200);
    return response;
  }
}
