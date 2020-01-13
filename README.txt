Usage instructions:

1) Run the listApps.sh to create a configuration file with all Applications in the environment. Schedule this to run at least once per day. 
  

2) Update "recreateAuditSchema.sh" with the correct access information, and run the script.

3) Update auditSnapshots.sh and audit_EUM_Sensitive_Data.sh with Account Specific information.

Execution is done using: 
     ./auditSnapshots.sh  Prod                     #(or Test), and
     ./audit_EUM_Sensitive_Data.sh Prod            #(or Test)

