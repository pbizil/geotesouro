<p align="center">
  <img width="770" height="410" src="https://github.com/pbizil/geotesouro/blob/main/imgs/1.png",
       href="https://oxy-data.shinyapps.io/geotesouro/">
</p>
<p align="center"> <img src = https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white >
<img src = https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54 > 
<img src = https://img.shields.io/badge/r-%23276DC3.svg?style=for-the-badge&logo=r&logoColor=white >
<img src = https://img.shields.io/badge/scikit--learn-%23F7931E.svg?style=for-the-badge&logo=scikit-learn&logoColor=white ></p>

**GeoTesouro é um protótipo de uma aplicação para identificação geoespacial das despesas da União.** Com esse trabalho, o objetivo é identificar, nos 5570 municípios brasileiros, quais despesas chegam naquela localidade. A plataforma pode ser acessada neste [link](https://oxy-data.shinyapps.io/geotesouro/).

Para identificar, de maneira inicial a localização das despesas, optou-se pelos seguintes temas:
- **Transferências Governamentais da União aos Municípios**, identificada pelo campo "Linguagem Cidadã" do Portal da Transparência;
- **Convênios**, celebrados da União com os municípios;
- **Emendas Parlamentares**, direcionadas exclusivamente aos municípios e plenamente identificada nos dados abertos;
- **Benefícios ao Cidadão**, ou seja, programas de transferência direta de renda aos cidadãos brasileiros: Bolsa Família, BPC, PETI, Seguro Defeso e Garantia-Safra.

Em geral, são temas relevantes no ponto de vista de transparência pública e podem ser aprimorados em termos de identificação geoespacial do dispêndio.

<p align="right">
  <img width="310" height="70" src="https://github.com/pbizil/geotesouro/blob/main/imgs/oxy.png">
</p>


## Machine Learning

Para incrementar a análise geolocalizada das despesas públicas do GeoTesouro, ao invés de dependermos de análises propriamente de tendências do passado ou de apenas estatísticas descritivas, optou-se por desenvolver um modelo de machine learning chamado `Cândido`, cujos resultados expressam probabilidades de terem alguma despesa naquela localidade ou o valor per capta transferido.  

<p align="center">
  <img height="130" src="https://github.com/pbizil/geotesouro/blob/main/imgs/logo_candido_maior.png">
</p>

Cândido é um ensemble, ou seja, um conjunto de modelos de machine learning que decidem sobre os valores per capta que são destinados aos municípios ou a probabilidade daquele município ter aquela despesa. Conforme explicitou a [didatica.tech](https://didatica.tech/metodos-ensemble/), estes metódos são:

> _"Estes métodos constroem vários modelos de machine learning, utilizando o resultado de cada modelo na definição de um único resultado, obtendo-se assim um valor final único. A resposta agregada de todos esses modelos é que será dada como o resultado final para cada dado que se está testando."_ 

A arquitetura do Cândido, portanto, envolveu não apenas um modelo único de estimação, mas a agregação de alguns importantes algoritmos de gradient boosting para aprimorar a estimação.

### Arquitetura - Cândido

**No Cândido, utilizou-se os três melhores modelos para performance de dados tabulares no mercado: [`XGBoost`](https://xgboost.readthedocs.io/en/stable/), [`LightGBM`](https://github.com/microsoft/LightGBM) e [`CatBoost`](https://github.com/catboost/catboost).** Com eles, estabeleceu-se um "comitê" - ou melhor: ensemble - no qual se decide sobre o problema através de uma outra camada também com um modelo mais simples de machine learning: Regrressão Linear, para problemas de regressão, e Regressão Logística, para problemas de probabilidade ou binários. Ambos os modelos da segunda camada foram utilizados com configurações default da biblioteca Scikit-Learn. 

Além da técnica de agregação de modelos, valeu-se de uma ferramenta para aprimorar a otimização dos hiperparâmetros dos três modelos da primeira camada: a
[`FLAML`](https://github.com/microsoft/FLAML), uma biblioteca open source da [`Microsoft Research`](https://github.com/microsoft). O objetivo com essa ferramenta é buscar a otimização com baixo custo e tempo reduzido, além de já fornecer os caminhos para armazenamento dos modelos para utilização no ensemble do Cândido.

<p align="center">
  <img src="https://github.com/pbizil/geotesouro/blob/main/imgs/candido_arquitetura.png">
</p>

### Estrutura de Estimação - Cândido

A estrutura de estimação tem como base estimar os valores dos temas deste trabalho através apenas de valores de informações geográficas (latitude, longitude, Estado e etc.), informações econômicas e demográficas. Com esses dados, o modelo estima dois tipos de valores: **os principais e os residuais**. 

Os resultados **principais** consistem em:

- Para Transferências, são os valores per capta do total de transferências a determinado município;
- Para Benefícios ao Cidadão, são o total de valores per capta de todos os benefícios destinados aos cidadãos daquele município;
- Para Convênios, é a probabilidade de determinado município celebrar algum convênio;
- Para Emendas, é a probabilidade de determinado município receber emendas parlamentares.

Os resultados **residuais** consistem em:

- Para Transferências, não há modelos residuais;
- Para Benefícios ao Cidadão, são os valores per capta de Bolsa Família e BPC, e as probabilidades do município ter algum cidadão que receba PETI, Seguro Defeso e Garantia-Safra;
- Para Convênios, é a probabilidade de Ministérios celebrarem Convênio com o município;
- Para Emendas, é a probabilidade de determinado partido destinar emendas parlamentares aos municípios.

<p align="center">
  <img src="https://github.com/pbizil/geotesouro/blob/main/imgs/candido_ensemble.png">
</p>


### Similaridades entre os Municípios - Modelagem

Outro modelo, mais simplório, desenvolvido foi o de similaridade entre os municípios. Com identificação entre municípios mais similares, é possível identificar localidades que possuem características mais próximas aos do município selecionado e estabelecer comparações do resultado do `Cândido`.

A modelagem de similaridades buscou identificar a similiridades entre os municípios através do método de [cosine similarity - ou similaridade do coseno](https://scikit-learn.org/stable/modules/generated/sklearn.metrics.pairwise.cosine_similarity.html), da biblioteca [Scikit-Learn](https://scikit-learn.org/). Com esse método, cada município, dada as suas características geográficas, econômicas e demográficas, é transformado em vetor e depois se compara através do coseno em um determinado espaço. Ao todo, construiu-se uma matriz de 5570 linhas, para cada município, com 10 colunas com a identificação dos municípios mais similares, através do código IBGE.

## Features

**Toda a experiência da plataforma gira em torno do município selecionado, no canto esquerdo da tela, como na imagem abaixo.** Na caixa seleção, é possível identificar os 5570 municípios brasileiros, que terão uma análise particular dos quatros pontos analisados neste trabalho.

<p align="center">
<img src="https://github.com/pbizil/geotesouro/blob/main/imgs/seletc_mun.PNG">
</p>

O protótipo da plataforma possui as quatros telas correspondentes a estes temas.

- Na tela de **Transferências Governamentais**, é possível de o usuário visualizar os valores correspondentes a estimação do valor per capta de transferências àquele município, além de posição no ranking nacional, comparação com municípios similares e acesso aos dados completos;
- Para a parte de **Benefícios ao Cidadão**, é possível de o usuário visualizar os valores correspondentes a estimação do valor per capta geral dos Benefícios ao Município, além dos valores per capta para Bolsa Família e BPC também para aquela localidade;
- Com relação aos **Convênios**, o usuário tem acesso à estimação de probabilidades do município selecionado celebrar Convênio, além do modelo residual identificando qual Ministério possui mais probabilidades de celebrá-lo, e comparação com municípios similares;
- As **Emendas Parlamentares** possuem features parecidas com a de Convênios: estimação de probabilidades, modelos residuais estimando a probabilidade de receber Emendas de determinado partido, comparação com municípios similares e acesso aos dados completos.

Além disso, há uma tela específica para análise dos **resultados do modelo Cândido**, também dividido nos temas correspondentes. Há, por fim, um box com resultados do modelo de similaridades, para consulta e download dos resultados.


<p align="center">
  <img src="https://github.com/pbizil/geotesouro/blob/main/imgs/tela_geotesouro1.png">
</p>


## Bases de dados

Para desenvolver este projeto, optou-se por dividir os dados em dois grupos:<b> os principais e os secundários</b>. Os principais foram responsáveis pelo desenvolvimento dos targets do modelo Cândido, enquanto os secundários são variáveis preditoras ou outros necessárias para execução do projeto. 

Os dados foram coletados via webcrawlers ou manualmente, em suas respectivas fontes. São armazenados em `SQLite`.

### Dados Principais

- [Transferências  - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/transferencias)
   - **Sobre:** Dados de todas as Transferências, obrigatórias ou voluntárias, feitas pela União aos municípios;
   - **Função:** Fonte da variável alvo, Trasnferências Governamentais per capta, para o modelo Cândido.

- [Convênios - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/convenios)
   - **Sobre:** Dados de Convênios celebrados pela União com os municípios, de 2010 a 2021;
   - **Função:** Fonte da variável alvo, proabilidade de celebrar um Convênio, para o modelo Cândido.

- [Emendas Parlamentares - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/emendas-parlamentares)
   - **Sobre:** Dados de Emendas Parlamentares identificadas por municípios;
   - **Função:** Fonte da variável alvo, proabilidade de receber uma Emenda, para o modelo Cândido.

- [Benefícios ao Cidadão - Bolsa Família - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/bolsa-familia-pagamentos)
   - **Sobre:** Dados de pagamentos de Bolsa Família por município, do período de 2013 a 2021;
   - **Função:** Fonte da variável alvo, valor total pago por município per capta, para o modelo Cândido.

- [Benefícios ao Cidadão - Benefício de Prestação Continuada (BPC) - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/bpc)
   - **Sobre:** Dados de pagamentos de BPC por município;
   - **Função:** Fonte da variável alvo, valor total pago por município per capta, para o modelo Cândido.

- [Benefícios ao Cidadão - Garantia-Safra - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/garantia-safra)
   - **Sobre:** Dados de pagamentos de Garantia-Safra por município;
   - **Função:** Fonte do modelo Cândido para estimação da probabilidade de haver pagamentos de Garantia-Safra em determinado município.

- [Benefícios ao Cidadão - Seguro Defeso (Pescador Artesanal) - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/seguro-defeso)
   - **Sobre:** Dados de pagamentos de Seguro Defeso por município;
   - **Função:** Fonte do modelo Cândido para estimação da probabilidade de haver pagamentos de Seguro-Defeso em determinado município.

- [Benefícios ao Cidadão - Erradicação do Trabalho Infantil (PETI) - CGU Portal da Transparência](https://www.portaltransparencia.gov.br/download-de-dados/peti)
   - **Sobre:** Dados de pagamentos do PETI por município;
   - **Função:** Fonte do modelo Cândido para estimação da probabilidade de haver pagamentos do PETI em determinado município.

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
   
