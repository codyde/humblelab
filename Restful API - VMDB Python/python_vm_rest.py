import pyodbc
import json
import collections
from flask import Flask, jsonify
from flask import abort
import getpass

pswd = getpass.getpass('Password:')

objects_list = []
conn =  pyodbc.connect(
        'DSN=humblesql01;' # as specified in /etc/odbc.ini
        'UID=sa;PWD='+pswd+';')
cursor = conn.cursor()

app = Flask(__name__)

def getdbjson():
	global objects_list
	cursor.execute("select * from otc.dbo.iaasmachine")
	rows = cursor.fetchall() 
	#objects_list = []
	for row in rows:
    		d = collections.OrderedDict()
    		d['UID'] = row.uid
    		d['hostname'] = row.hostname
    		d['requestor'] = row.requestor
    		d['orderNumber'] = row.orderNumber
    		d['totalDisk'] = row.totalDisk
    		d['requestCPU'] = row.requestCPU
    		d['applicationRequest'] = row.applicationRequest
    		d['requestStartDate'] = row.requestStartDate
    		d['requestEndDate'] = row.requestEndDate
    		d['iaascomputeCost'] = row.iaascomputeCost
    		d['iaasstorageCost'] = row.iaasstorageCost
    		d['capitalCost'] = row.capitalCost
    		objects_list.append(d)
	#j = json.dumps(objects_list, indent=4, sort_keys=True)
	#print(j)

@app.route('/humblelab/api/v1.0/vms', methods=['GET'])
def get_vms():
	getdbjson()
	return jsonify({'vms': objects_list})

@app.route('/humblelab/api/v1.0/vms/<string:hostname>', methods=['GET'])
def get_hostname(hostname):
	getdbjson()
	host = [host for host in objects_list if host['hostname'] == hostname]
	if len(host) == 0:
		abort(404)
	return jsonify({'hostname': host[0]})

@app.route('/humblelab/api/v1.0/vms/<string:requestor>', methods=['GET'])
def get_uservms(requestor):
	getdbjson()
	user = [user for user in objects_list if user['requestor'] == requestor]
	if len(user) == 0:
		abort(404)
	return jsonify({'requestor': user[0]})


if __name__ == '__main__':
	app.run(debug=True)
