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

## Passo a passo

Obs.: Passo a passo para usuários de Windows.
No seu cmd, siga os passos abaixo:
flowchart TD
    A[Início] --> B[Criar venv<br>python -m venv desafio_meli]
    B --> C[Ativar venv<br>Scripts\\activate]
    C --> D[Instalar dependências<br>pip install -r requirements.txt]
    D --> E[Navegar até 02_Code<br>extract_compliance_data.py]
    E --> F[Executar script<br>python extract_compliance_data.py]
    F --> G[Gerar CSV bruto]
    G --> H[Aplicar json_normalize]
    H --> I[Gerar CSV normalizado]
    I --> J[Fim]

Obs.: Passo a passo para usuários de Windows.
No seu cmd, siga os passos abaixo: 
1. Criar o ambiente virtual com o código python -m venv "nome_sua_escolha", por exemplo, python -m venv desafio_meli. 
2. Ativar sua venv: cd "nome_sua_escolha" e depois o seguinte comando: Scripts\activate 
3. Instalar requirements: pip install -r requirements.txt - Garanta que requirements está na pasta criada da sua venv (Provavelmente C:\Users\"User"\"nome_sua_escolha") 
4. Ainda com sua venv ativada, navegue até o caminho arquivo em questão: extract_compliance_data.py - Caso sua árvore de diretórios siga o padrão do repositório será aqui: "C:\Users\"User"\"nome_sua_escolha"\project\02_Code" 
5. rode o arquivo com python extract_compliance_data.py 
6. Verifique o diretório 01_Datasets pelos arquivos gerados. Para funcionar lembre de ter o python instalado, versão usada para desenvolvimento 3.11

## Bloqueios

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

Possíveis bloqueios: 
1. Token expirado ou ausente -> Armazenamento em .env
2. Header mal formatado -> Validações antes da request
3. Limite de chamadas -> redução de solicitações ou diminuir frequência de chamadas.
4. Formatação do JSON -> Usar Try/Except e get()
5. Timeout -> Limitado
6. Instalação do ambiente python -> Versionamento de libs e PATH corretos.