<p align="center">
  <img width="770" height="410" src="https://github.com/pbizil/geotesouro/blob/main/imgs/2.png">
</p>
<p align="center"> <img src = https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white >
<img src = https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54 > 
<img src = https://img.shields.io/badge/r-%23276DC3.svg?style=for-the-badge&logo=r&logoColor=white >
<img src = https://img.shields.io/badge/scikit--learn-%23F7931E.svg?style=for-the-badge&logo=scikit-learn&logoColor=white ></p>

GeoTesouro é um protótipo de uma aplicação para identificação geoespacial das despesas da União. Pra este trabalho, optou-se, de maneira estratégica, por quatro temas, que se consubstanciam: Transferências Governamentais - na qual se engloba todas as transferências; Benefícios ao Cidadão; Convênios; Emendas Parlamentares

Em geral, são temas relevantes no ponto de vista de transparência pública e podem ser aprimorados em termos de identificação geoespacial do dispêndio.

<p align="right">
  <img width="310" height="70" src="https://github.com/pbizil/geotesouro/blob/main/imgs/oxy.png">
</p>

## Machine Learning

Para incrementar a análise geolocalizada das despesas públicas do GeoTesouro, ao invés de dependermos de análises propriamente de tendências do passado ou de apenas estatísticas descritivas, optou-se por desenvolver um modelo de machine learning chamado `Cândido`, cujos resultados expressam probabilidades de terem alguma despesa naquela localidade ou o valor per capta transferido.  

<p align="center">
  <img height="130" src="https://github.com/pbizil/geotesouro/blob/main/imgs/logo_candido_maior.png">
</p>

<p align="center">
  <img src="https://github.com/pbizil/geotesouro/blob/main/imgs/candido_arquitetura.png">
</p>


_"Estes métodos constroem vários modelos de machine learning, utilizando o resultado de cada modelo na definição de um único resultado, obtendo-se assim um valor final único. A resposta agregada de todos esses modelos é que será dada como o resultado final para cada dado que se está testando."_ 


<p align="center">
  <img src="https://github.com/pbizil/geotesouro/blob/main/imgs/candido_ensemble.png">
</p>

## Features




## Bases de dados

Para desenvolver este projeto, optou-se por dividir os dados em dois grupos:<b> os principais e os secundários</b>.

### Dados Principais

- [Transferências  - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/transferencias)
   - **Sobre:** ;
   - **Função:** .

- [Convênios - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/convenios)
   - **Sobre:** ;
   - **Função:** .

- [Emendas Parlamentares - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/emendas-parlamentares)
   - **Sobre:** ;
   - **Função:** .

- [Benefícios ao Cidadão - Bolsa Família - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/bolsa-familia-pagamentos)
   - **Sobre:** ;
   - **Função:** .

- [Benefícios ao Cidadão - Benefício de Prestação Continuada (BPC) - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/bpc)
   - **Sobre:** ;
   - **Função:** .

- [Benefícios ao Cidadão - Garantia-Safra - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/garantia-safra)
   - **Sobre:** ;
   - **Função:** .

- [Benefícios ao Cidadão - Seguro Defeso (Pescador Artesanal) - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/seguro-defeso)
   - **Sobre:** ;
   - **Função:** .

- [Benefícios ao Cidadão - Erradicação do Trabalho Infantil (PETI) - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/peti)
   - **Sobre:** ;
   - **Função:** .

### Dados Secundários

- [Informações gerais dos municípios - Tabela RAW Github](https://github.com/kelvins/Municipios-Brasileiros)
   - **Sobre:** Dados de código IBGE, nome do município, capital, código UF, UF, estado, latitude, longitude, código SIAFI, DDD e fuso horário de todos (ou quase todos) os municípios brasileiros. Total de 5.570 registros;
   - **Função:** código SIAFI e IBGE são instrumentos de agregação de tabelas. Outros dados são para variáveis preditoras do modelo Cândido.

- [População Municipal - BaseDosDados](https://basedosdados.org/dataset/br-ibge-populacao?bdm_table=municipio)
   - **Sobre:** Fornece estimativas do total da população dos Municípios e das Unidades da Federação brasileiras, com data de referência em 1o de julho, para o ano calendário corrente. As estimativas populacionais foram coletadas desde 1991 até 2021;
   - **Função:** Entram como variáveis preditivas do modelo Cândido.
   
- [Produto Interno Bruto Municipal - BaseDosDados](https://basedosdados.org/dataset/br-ibge-pib?bdm_table=municipio)
   - **Sobre:** Produto Interno Bruto (PIB) municipal a preços correntes. De 2002 a 2019.;
   - **Função:** Entram como variáveis preditivas do modelo Cândido.

- [Dados Espaciais - GeoBR](https://github.com/ipeaGIT/geobr)
   - **Sobre:** GeoBR é um pacote R que permite que os usuários acessem facilmente os shapefiles do Instituto Brasileiro de Geografia e Estatística (IBGE) e outros conjuntos oficiais de dados espaciais do Brasil;
   - **Função:** Os dados coletados foram utilizados para criar as visualizações geoespaciais com a biblioteca [leaflet](https://github.com/rstudio/leaflet).
   
- [Câmara dos Deputados - API Dados Abertos](https://dadosabertos.camara.leg.br/swagger/api.html)
   - **Sobre:** Requisição de nome e partido dos deputados federais, por legislatura;
   - **Função:** coletou-se o nome e partido destes parlamentares para construir os modelos residuais de Emendas Parlamentares.
   
- [Senado Federal - API Dados Abertos](https://www12.senado.leg.br/dados-abertos/conjuntos?portal=Legislativo&grupo=senadores)
   - **Sobre:** requisição de nome e partido dos senadores, por legislatura;
   - **Função:**  coletou-se o nome e partido destes parlamentares para construir os modelos residuais de Emendas Parlamentares.
   
