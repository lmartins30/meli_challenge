# Compliance Alerts Pipeline

Este projeto simula a coleta, normalização e análise de alertas de compliance a partir de uma API.

## Arquitetura da Solução

```mermaid
flowchart TD
    A[Lista de alert_ids] --> B[Loop em Python]
    B --> C[GET na API<br>ou JSON Simulado]
    C --> D[Coleta dos Dados Brutos]
    D --> E[Geração de CSV]
    E --> F[Normalização com pandas.json_normalize]
    F --> G[Análise e Visualização]
```

## Passo a passo

### Diagrama dos Passos
```mermaid
flowchart TD
    A[Início] --> B[Criar venv<br>python -m venv desafio_meli]
    B --> C[Ativar venv<br>Scripts\activate]
    C --> D[Instalar dependências<br>pip install -r requirements.txt]
    D --> E[Navegar até 02_Code<br>extract_compliance_data.py]
    E --> F[Executar script<br>python extract_compliance_data.py]
    F --> G[Gerar CSV bruto]
    G --> H[Aplicar json_normalize]
    H --> I[Gerar CSV normalizado]
    I --> J[Fim]
```

### Passos detalhados (Windows)

1. Criar o ambiente virtual com o código:  
   `python -m venv "nome_sua_escolha"` (ex: `python -m venv desafio_meli`)

2. Ativar a venv:  
   ```
   cd "nome_sua_escolha"
   Scripts\activate
   ```

3. Instalar requirements:  
   `pip install -r requirements.txt`  
   > Certifique-se de que `requirements.txt` está na pasta da venv.

4. Ainda com a venv ativada, navegue até o arquivo:  
   `extract_compliance_data.py`  
   Caminho esperado:  
   `C:\Users\"User"\"nome_sua_escolha"\project\02_Code`

5. Rodar o script:  
   `python extract_compliance_data.py`

6. Verificar arquivos gerados em:  
   `01_Datasets/`

> Requer: Python 3.11

---

## Possíveis Bloqueios e Estratégias

### Diagrama de Bloqueios
```mermaid
flowchart TD
    A[Interação com API] --> B[Erro de Autenticação]
    A --> C[Limite de Taxa (Rate Limit)]
    A --> D[JSON Irregular ou Profundo]
    A --> E[Falha de Rede]
    A --> F[Ambiente Python]

    B --> B1[→ Estratégia:<br>Verificar token,<br>renovar credenciais,<br>usar .env]
    C --> C1[→ Estratégia:<br>Retry com backoff,<br>pausas progressivas]
    D --> D1[→ Estratégia:<br>Validações,<br>try/except,<br>json_normalize com parâmetros]
    E --> E1[→ Estratégia:<br>Timeouts,<br>retry,<br>fallback para JSON simulado]
    F --> F1[→ Estratégia:<br>Conferir venv,<br>versão do Python,<br>pacotes instalados]
```

### Lista Explicada

1. **Token expirado ou ausente**  
   - Mitigação: configurar variáveis de ambiente `.env`, validar antes da request.

2. **Headers mal formatados**  
   - Mitigação: validações pré-request.

3. **Limite de chamadas por segundo (Rate Limit)**  
   - Mitigação: retry com *exponential backoff*, uso de cache local.

4. **Formatação do JSON variável**  
   - Mitigação: `try/except`, `.get()`, normalização incremental.

5. **Timeout ou falhas de rede**  
   - Mitigação: timeouts explícitos, múltiplas tentativas, JSON simulado.

6. **Problemas no ambiente Python**  
   - Mitigação: versionamento, requirements fixo, garantir PATH funcional.
