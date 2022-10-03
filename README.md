<p align="center">
  <img width="770" height="410" src="https://github.com/pbizil/geotesouro/blob/main/imgs/2.png">
</p>

Geotesouro é um protótipo de...

Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.

<p align="right">
  <img width="310" height="70" src="https://github.com/pbizil/geotesouro/blob/main/imgs/oxy.png">
</p>

## Machine Learning

<p align="center">
  <img height="130" src="https://github.com/pbizil/geotesouro/blob/main/imgs/logo_candido_maior.png">
</p>

<p align="center">
  <img src="https://github.com/pbizil/geotesouro/blob/main/imgs/candido_explica.png">
</p>


## Features



## Bases de dados

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
   
