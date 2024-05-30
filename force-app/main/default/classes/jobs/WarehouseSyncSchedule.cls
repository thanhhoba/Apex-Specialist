public with sharing class WarehouseSyncSchedule implements Schedulable {
  public void execute(SchedulableContext context) {
    WarehouseCalloutService job = new WarehouseCalloutService();
    System.enqueueJob(job);
  }
}
// Scheduling a Job from the UI - Apex Class - Add Job
