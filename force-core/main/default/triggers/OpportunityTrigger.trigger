trigger OpportunityTrigger on Opportunity (before insert, before update,
                                            after insert, after update,
                                            before delete, after delete,
                                            after undelete) 
{

  // delegate trigger processing for ALL triggers to the trigger
  // dispatcher
  TriggerDispatcher.handleTrigger('Opportunity', trigger.OperationType,
                                    trigger.new, trigger.newMap,
                                    trigger.old, trigger.oldMap);

}