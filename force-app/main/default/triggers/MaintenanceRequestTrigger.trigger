trigger MaintenanceRequestTrigger on Case(after update) {
  List<Case> closedRequests = new List<Case>();
  for (Case c : Trigger.new) {
    if (
      c.Status == 'Closed' &&
      (c.Type == 'Repair' ||
      c.Type == 'Routine Maintenance') &&
      Trigger.oldMap.get(c.Id).Status != 'Closed'
    ) {
      closedRequests.add(c);
    }
  }

  if (closedRequests.size() > 0) {
    MaintenanceRequestHelper.createRoutineMaintenanceRequests(closedRequests);
  }
}
