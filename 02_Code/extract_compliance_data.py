# Imports
# -----------------------
import requests
import random
import json
import pandas as pd
from datetime import datetime, timedelta
# -----------------------

# Funcs
# -----------------------
def simula_json(alert_ids):
    """
    Gera um JSON com os detalhes dos alertas usando a lista de IDs real.
    """
    types = ["tax_incident", "invoice_discrepancy", "missing_document", "regulatory_review"]
    regions = ['BR', 'LATAM', 'MEX']
    statuses = ["open", "in_progress", "resolved"]
    assignees = ["team_a", "team_b", "team_c", "external_partner"]
    impact_levels = ["low", "medium", "high", "critical"]
    sources = ["SAP", "Internal_Tracker", "Vendor_API"]
    alerts = []

    for alert_id in alert_ids:
        creation_date = datetime.now() - timedelta(days=random.randint(0, 400))
        resolution_date = creation_date + timedelta(days=random.randint(1,15))

        alert = {
            "alert_id": alert_id,
            "type_of_alert": random.choice(types),
            "status": random.choice(statuses),
            "assigned_to": random.choice(assignees),
            "creation_date": creation_date.isoformat(),
            "resolution_date": resolution_date.isoformat(),
            "impact_level": random.choice(impact_levels),
            "region": random.choice(regions),
            "source": random.choice(sources)
        }
        alerts.append(alert)

    alerts_json = json.dumps(alerts)
    return alerts_json

def simular_json_response_lista(num_ids=100):
    """
    Cria a estrutura de dados Python (dicionário) que simula a resposta
    da API 'compliance_alerts?status=open&limit=100'.
    """
    # Gera 100 IDs (COMP-ALERT-10000 até COMP-ALERT-10099)
    ids_simulados = [{"id": f"COMP-ALERT-{i}"} for i in range(10000, 10000 + num_ids)]
    
    # Estrutura de resposta (com 'paging' e a lista em 'results')
    response_data = {
        "paging": {
            "total": num_ids, 
            "offset": 0, 
            "limit": num_ids
        },
        "results": ids_simulados
    }
    return response_data
# -----------------------

# Defs
# -----------------------
url_list_alerts = "https://api.mercadolibre.com/compliance_alerts?status=open&limit=100"
# -----------------------

# Code
# -----------------------
# Do not run block below, API is fake.
# try:
#     response = requests.get(url_list_alerts, timeout=5)
#     response.raise_for_status()

#     data = response.json()
#     results = data.get("results",[])
#     if not results:
#         if results is None:
#             raise ValueError("Formato inesperado: chave 'results' ausente")
#         else:
#             print("Nenhum alerta encontrado")
#     alert_ids = [item.get("id") for item in results if item.get("id")]
#     print("IDs lidos com sucesso")

# except Exception as e:
#     print("Erro: ", e)


# Once the API is fake, simulating alert_ids
data = simular_json_response_lista()
alert_ids = [item.get("id") for item in data.get("results", [])]

# creating alert details
alert_json = simula_json(alert_ids)
alert_json = json.loads(alert_json)

# Do not run block below, API is fake.
# alert_detail = []
# for alert_id in alert_ids:
#     url = f"https://api.mercadolibre.com/compliance_alerts/{alert_id}"
#     try:
#         # response = requests.get(url, timeout=5)
#         response.raise_for_status()

#         data = response.json()
#         alert_detail.append(data)

#     except Exception as e:
#         print("Erro: ", e)

# Once the API is fake, simulating alert_details
alert_detail = []

for alert_id in alert_ids:
    match = [alert for alert in alert_json if alert['alert_id'] == alert_id]

    if match:
        alert_detail.append(match[0])
    else:
        print("ID não encontrado")

# Creating csv in the correct folder
df = pd.DataFrame(alert_detail)
df.to_csv("../01_Datasets/alert_detail.csv")

cols = cols = ['alert_id', 'type_of_alert', 'status', 'assigned_to', 'creation_date', 'resolution_date', 'impact_level']

df_normalized = pd.json_normalize(alert_detail)
df_normalized = df_normalized[cols]
df_normalized.to_csv("../01_Datasets/alert_detail_normalized.csv")