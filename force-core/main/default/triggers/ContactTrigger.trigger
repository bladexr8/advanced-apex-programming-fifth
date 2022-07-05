trigger ContactTrigger on Contact (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.handleTrigger('Contact', trigger.OperationType, trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
}