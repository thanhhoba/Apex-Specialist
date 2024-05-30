@isTest
private class WarehouseSyncScheduleTest {
  @isTest
  static void testWarehouseSyncSchedule() {
    // Create mock products
    List<Product2> products = MaintenanceRequestFake.createEquipments(2);
    Set<String> setIds = new Set<String>();
    for (Product2 product : products) {
      setIds.add(product.Id);
    }

    // Set the mock callout
    Test.setMock(
      HttpCalloutMock.class,
      new WarehouseCalloutServiceMock(setIds)
    );

    Test.startTest();

    // This cron expression schedules the job to run daily at 1 AM
    String cronExp = '0 0 1 * * ?';
    String jobId = System.schedule(
      'Test Warehouse Sync',
      cronExp,
      new WarehouseSyncSchedule()
    );

    // Execute the scheduled job immediately
    CronTrigger ct = [
      SELECT Id, CronExpression, TimesTriggered, NextFireTime
      FROM CronTrigger
      WHERE Id = :jobId
    ];

    Test.stopTest();

    // Fetch the job from the AsyncApexJob table to verify it's been enqueued
    List<AsyncApexJob> jobs = [
      SELECT Id, JobType, Status, ApexClass.Name
      FROM AsyncApexJob
      WHERE JobType = 'Queueable'
    ];

    // Assertions
    System.assertEquals(
      1,
      jobs.size(),
      'Expected one Queueable job to be enqueued.'
    );
    System.assertEquals(
      'WarehouseCalloutService',
      jobs[0].ApexClass.Name,
      'Expected the WarehouseCalloutService job to be enqueued.'
    );
  }
}
