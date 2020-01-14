import json
 
with open('/Applications/AppDynamics/data/AppdCustomReports/tmpFile.json', 'r') as handle:
        parsed = json.load(handle)
print(json.dumps(parsed, indent=4, sort_keys=True))
