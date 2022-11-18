library(shiny)
library(shinydashboard)
library(bs4Dash)
library(DBI)
library(leaflet)
library(leaflet.extras)
library(sp)
library(geobr)
library(sf)
library(rgdal)
library(leafgl)
library(tidyr)
library(waiter)
library(scales)
library(DT)
library(shinyjs)
library(plotly)
library(dplyr)
library(shinycustomloader)
library(fresh)
library(ggplot2)

setwd("~/Desktop/geotesouro")

### CARGA DADOS

con <- dbConnect(RSQLite::SQLite(), "data/data.db")
agg_municipios <- dbReadTable(con, "agg_municipios")
transferencias <- dbReadTable(con, "transferencias")
preds_transf <- dbReadTable(con, "preds_transf")
#convenios <- dbReadTable(con, "convenios")
preds_convenios <- dbReadTable(con, "preds_convenios")
emendas <- dbReadTable(con, "emendas")
preds_emendas <- dbReadTable(con, "preds_emendas")
bolsa_familia <- dbReadTable(con, "bolsa_familia")
bpc <- dbReadTable(con, "benef_cidadad - bpc")
garantia_safra <- dbReadTable(con, "benef_cidadad - garantia_safra")
seguro_defeso <-  dbReadTable(con, "benef_cidadad - seguro_defeso")
peti <-  dbReadTable(con, "benef_cidadad - peti")
preds_beneficios <- dbReadTable(con, "preds_beneficios")
performance_mdl <- dbReadTable(con, "performance_mdl")
performance_mdl_reg <- dbReadTable(con, 'performance_mdl_reg')
similaridades <- dbReadTable(con, "similaridades")
dbDisconnect(con)

### TRANSFORM DADOS

agg_municipios$nome_composto <- paste(agg_municipios$nome, " - ", agg_municipios$uf_sigla)
agg_municipios$pib_per_capta <- agg_municipios$pib_2019 / agg_municipios$pop_2019

bolsa_familia <- bolsa_familia[order(bolsa_familia$ano_mes),]
bpc <- bpc[order(bpc$ano_mes),]
garantia_safra <- garantia_safra[order(garantia_safra$ano_mes),]
seguro_defeso <- seguro_defeso[order(seguro_defeso$ano_mes),]
peti <- peti[order(peti$ano_mes),]


### APP DEV

ui <- dashboardPage(
  dark = NULL,
  dashboardHeader(title = dashboardBrand(
    title = "  Tesouro Transparente",
    color = "secondary",
    href = "https://www.tesourotransparente.gov.br/",
    image = "https://github.com/pbizil/geotesouro/blob/main/imgs/stn_branco.png?raw=true"),
  status = "secondary"),
  dashboardSidebar(skin = "light", status = "secondary", width = "300px", id = "sidebar",
                   div(tags$img(src = "https://github.com/pbizil/geotesouro/blob/main/imgs/1.png?raw=true", width="100%")),
                   uiOutput("escolha_mun"),
                   sidebarMenu(id = "sidebarMenu", 
                    bs4SidebarHeader("Temas"),
                    menuItem(text = "Transferências", tabName = "menu_trans", icon = icon("exchange")),
                    menuItem(text = "Benefícios ao cidadão", tabName = "menu_benef", icon = icon("hand-holding-usd")),
                    menuItem(text = "Convênios", tabName = "menu_conv", icon = icon("hands-helping")),
                    menuItem(text = "Emendas Parlamentares", tabName = "menu_parl", icon = icon("user-tie")),
                    bs4SidebarHeader("Outros"),
                    menuItem(text = "CÂNDIDO", tabName = "menu_candido", icon = icon("angle-double-up")),
                    menuItem(text = "Sobre o projeto", tabName = "menu_about", icon = icon("project-diagram"))
                   )),
  dashboardBody(use_theme(create_theme(bs4dash_layout(main_bg = "#FFFFFF", sidebar_width = "280px"))),
                use_waiter(),
                shinyjs::useShinyjs(),
    bs4TabItems(
      bs4TabItem("menu_trans",
                 fluidRow(column(6, bs4InfoBoxOutput("ibox_mun_transf", width = 12)),
                          column(3, bs4InfoBoxOutput("ibox_pop_transf", width = 12)),
                          column(3, bs4InfoBoxOutput("ibox_pib_transf", width = 12))),
                 br(),
                 fluidRow(bs4ValueBoxOutput("vbox_transf_candido", width = 3),
                          bs4ValueBoxOutput("vbox_transf_media_sims", width = 3),
                          bs4ValueBoxOutput("vbox_transf_media_estado", width = 3),
                          bs4ValueBoxOutput("vbox_transf_ranking", width = 3)),
                 br(),
                 fluidRow(column(6, bs4Card(elevation = 1, title = "Valor Total Transferências por Tema - 2021", width = 12, plotlyOutput("graf_transf_2021", height = 900), closable = FALSE, collapsible =  FALSE)), 
                          column(6, fluidRow(bs4Card(elevation = 1, title = "Valor Per Capta - Municípios Similares - #PredictCândido", width = 12, plotlyOutput("graf_transf_sims"), closable = FALSE, collapsible =  FALSE)),
                                 fluidRow(bs4Card(elevation = 1, title = "Distribuição - Valor Per Capta - Todos Municípios Brasileiros", width = 12, plotlyOutput("graf_transf_hist"), closable = FALSE, collapsible =  FALSE)))),
                 br(),
                 tabBox(elevation = 1, width = 12, status = "gray", closable = FALSE, collapsible = FALSE, solidHeader = FALSE,
                        title = "Tabelas - Transferências", type = "tabs",
                        tabPanel(title = "Transferências", fluidRow(column(12, DT::dataTableOutput("table_transferencias")))))),
      bs4TabItem("menu_conv",
                fluidRow(column(6, bs4InfoBoxOutput("ibox_mun_conv", width = 12)),
                         column(3, bs4InfoBoxOutput("ibox_pop_conv", width = 12)),
                         column(3, bs4InfoBoxOutput("ibox_pib_conv", width = 12))),
                 br(),
                fluidRow(bs4ValueBoxOutput("vbox_conv_candido", width = 3),
                          bs4ValueBoxOutput("vbox_conv_media_sims", width = 3),
                         bs4ValueBoxOutput("vbox_conv_media_estado", width = 3),
                         bs4ValueBoxOutput("vbox_conv_ranking", width = 3)),
                br(),
                fluidRow(column(6, bs4Card(elevation = 1, title = "Probab. Convênio por Ministério - #PredictCândido", width = 12, closable = FALSE, collapsible =  FALSE,
                                           plotlyOutput("graf_conv_residual_mins",  height = 900))), 
                         column(6, fluidRow(bs4Card(elevation = 1, title = "Probab. - Municípios Similares - #PredictCândido", width = 12, plotlyOutput("graf_conv_sims"), closable = FALSE, collapsible =  FALSE)),
                                fluidRow(bs4Card(elevation = 1, title = "Distribuição - Probab. Convênios - Muns. Brasileiros", width = 12, plotlyOutput("graf_conv_hist"), closable = FALSE, collapsible =  FALSE)))),
                br(),
                tabBox(elevation = 1, width = 12, status = "gray", closable = FALSE, collapsible = FALSE, solidHeader = FALSE,
                        title = "Tabela - Convênios", type = "tabs",
                  tabPanel(title = "Convênios", fluidRow(column(12, 
                                                                withLoader(DT::dataTableOutput("table_convenios"), type = "html", loader = "loader1")))))),
      bs4TabItem("menu_parl",
                 fluidRow(column(6, bs4InfoBoxOutput("ibox_mun_emendas", width = 12)),
                          column(3, bs4InfoBoxOutput("ibox_pop_emendas", width = 12)),
                          column(3, bs4InfoBoxOutput("ibox_pib_emendas", width = 12))),
                 br(),
                 fluidRow(bs4ValueBoxOutput("vbox_emendas_candido", width = 3),
                          bs4ValueBoxOutput("vbox_emendas_media_sims", width = 3),
                          bs4ValueBoxOutput("vbox_emendas_media_estado", width = 3),
                          bs4ValueBoxOutput("vbox_emendas_ranking", width = 3)),
                 br(),
                 fluidRow(column(6, bs4Card(elevation = 1, title = "Probab. Parl. por Partido - #PredictCândido", width = 12, closable = FALSE, collapsible =  FALSE,
                                            plotlyOutput("graf_emendas_residual_mins",  height = 900))), 
                          column(6, fluidRow(bs4Card(elevation = 1, title = "Probab. Emendas Parl. - Municípios Similares - #PredictCândido", width = 12, plotlyOutput("graf_emendas_sims"), closable = FALSE, collapsible =  FALSE)),
                                 fluidRow(bs4Card(elevation = 1, title = "Distribuição - Probab. Emendas Parl. - Muns. Brasileiros", width = 12, plotlyOutput("graf_emendas_hist"), closable = FALSE, collapsible =  FALSE)))),
                 br(),
                 tabBox(elevation = 1, width = 12, status = "gray", closable = FALSE, collapsible = FALSE, solidHeader = FALSE,
                        title = "Tabelas - Transferências", type = "tabs",
                        tabPanel(title = "Transferências", fluidRow(column(12, DT::dataTableOutput("table_emendas")))))),
      bs4TabItem("menu_benef",
                 fluidRow(column(6, bs4InfoBoxOutput("ibox_mun_benef", width = 12)),
                          column(3, bs4InfoBoxOutput("ibox_pop_benef", width = 12)),
                          column(3, bs4InfoBoxOutput("ibox_pib_benef", width = 12))),
                 br(),
                 fluidRow(bs4ValueBoxOutput("vbox_benef_candido", width = 3),
                          bs4ValueBoxOutput("vbox_benef_media_sims", width = 3),
                          bs4ValueBoxOutput("vbox_benef_media_estado", width = 3),
                          bs4ValueBoxOutput("vbox_benef_ranking", width = 3)),
                 br(),
                 fluidRow(column(12, bs4Card(elevation = 1, title = "Valores de Benefícios ao Cidadão - Mensal - por tipo", 
                                             width = 12, closable = FALSE, collapsible =  FALSE,
                                             plotlyOutput("graf_beneficios_mensal")))),
                 br(),
                 fluidRow(column(6, bs4Card(elevation = 1, title = "Valor Per Capta - BPC e Bolsa Família - #PredictCândido", width = 12, closable = FALSE, collapsible =  FALSE,
                                            plotlyOutput("graf_beneficios_residual_valor_per_capta"))), 
                          column(6, bs4Card(elevation = 1, title = "Probabs. - PETI, Seguro Defeso e Garantia-Safra - #PredictCândido", width = 12, closable = FALSE, collapsible =  FALSE,
                                            plotlyOutput("graf_beneficios_residual_probs")))),
                 fluidRow(column(6, bs4Card(elevation = 1, title = "Valor Per Capta Benefícios - Municípios Similares - #PredictCândido", 
                                            width = 12, plotlyOutput("graf_beneficios_sims"), closable = FALSE, collapsible =  FALSE)), 
                 column(6, bs4Card(elevation = 1, title = "Distribuição - Valor Per Capta Benefícios - Todos Municípios Brasileiros", 
                                   width = 12, plotlyOutput("graf_beneficios_hist"), closable = FALSE, collapsible =  FALSE))),
                 br(),
                 tabBox(elevation = 1, width = 12, status = "gray", closable = FALSE, collapsible = FALSE, solidHeader = FALSE,
                        title = "Tabelas - Benefícios ao Cidadão", type = "tabs",
                        tabPanel(title = "Bolsa Família", fluidRow(column(12, DT::dataTableOutput("table_benef_bolsa_familia")))),
                        tabPanel(title = "BPC - Benefício de Prestação Continuada", fluidRow(column(12, DT::dataTableOutput("table_benef_bpc")))),
                        tabPanel(title = "Garantia-Safra", fluidRow(column(12, DT::dataTableOutput("table_benef_garantia_safra")))),
                        tabPanel(title = "Seguro Defeso", fluidRow(column(12, DT::dataTableOutput("table_benef_seguro_defeso")))),
                        tabPanel(title = "PETI - Programa de Erradicação do Trabalho Infantil", fluidRow(column(12, DT::dataTableOutput("table_benef_peti")))))),
      bs4TabItem("menu_candido",
                 fluidRow(column(1), 
                          column(10,tags$img(width = "100%", src = "https://github.com/pbizil/geotesouro/blob/main/imgs/logo_candido_maior.png?raw=true")),
                          column(1)),
                 br(),
                 fluidRow(bs4Card(elevation = 1, title = tags$b("CÂNDIDO - Transferências - Relatório Modelo"), closable = FALSE, width = 12, status = "white", 
                                  solidHeader = TRUE, collapsible = TRUE,  maximizable = TRUE, 
                                  fluidRow(column(3, bs4ValueBoxOutput("vbox_rel_transf_xgb", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_transf_lgbm", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_transf_cb", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_transf_candido", width = 12)),
                                           br(),
                                           column(4, plotOutput("plot_rel_transf_r2")), column(4, plotOutput("plot_rel_transf_mse")), column(4, plotOutput("plot_rel_transf_rmse")),
                                           br(),
                                           column(12, DT::dataTableOutput("table_rel_transf"))))),
                 fluidRow(bs4Card(elevation = 1, title = tags$b("CÂNDIDO - Convênios - Relatório"), closable = FALSE, width = 12, status = "white", 
                                  solidHeader = TRUE, collapsible = TRUE, collapsed = TRUE, maximizable = TRUE, 
                                  fluidRow(column(6, uiOutput("select_rel_conv"))),
                                  br(),
                                  fluidRow(column(3, bs4ValueBoxOutput("vbox_rel_conv_xgb", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_conv_lgbm", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_conv_cb", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_conv_candido", width = 12))),
                                  br(),
                                  fluidRow(column(4, plotOutput("plot_rel_conv_acc")), column(4, plotOutput("plot_rel_conv_roc_auc")), column(4, plotOutput("plot_rel_conv_log_loss"))),
                                  br(),
                                  column(12, DT::dataTableOutput("table_rel_conv")))),
                 fluidRow(bs4Card(elevation = 1, title = tags$b("CÂNDIDO - Emendas Parlamentares - Relatório"), closable = FALSE, width = 12, status = "white", 
                                  solidHeader = TRUE, collapsible = TRUE, collapsed = TRUE,  maximizable = TRUE, 
                                  fluidRow(column(6, uiOutput("select_rel_emendas"))),
                                  br(),
                                  fluidRow(column(3, bs4ValueBoxOutput("vbox_rel_emendas_xgb", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_emendas_lgbm", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_emendas_cb", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_emendas_candido", width = 12))),
                                  br(),
                                  fluidRow(column(4, plotOutput("plot_rel_emendas_acc")), column(4, plotOutput("plot_rel_emendas_roc_auc")), column(4, plotOutput("plot_rel_emendas_log_loss"))),
                                  br(),
                                  column(12, DT::dataTableOutput("table_rel_emendas")))),
                 fluidRow(bs4Card(elevation = 1, title = tags$b("CÂNDIDO - Benefícios ao Cidadão - Relatório"), closable = FALSE, width = 12, status = "white", 
                                  solidHeader = TRUE, collapsible = TRUE, collapsed = TRUE,  maximizable = TRUE,
                                  fluidRow(column(6, uiOutput("select_rel_benef"))),
                                  br(),
                                  fluidRow(column(3, bs4ValueBoxOutput("vbox_rel_benef_xgb", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_benef_lgbm", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_benef_cb", width = 12)),
                                           column(3, bs4ValueBoxOutput("vbox_rel_benef_candido", width = 12))),
                                  br(),
                                  fluidRow(column(4, plotOutput("plot_rel_benefs_1")), column(4, plotOutput("plot_rel_benefs_2")), column(4, plotOutput("plot_rel_benefs_3"))),
                                  br(),
                                  column(12, DT::dataTableOutput("table_rel_benef")))),
                 fluidRow(bs4Card(elevation = 1, title = tags$b("CÂNDIDO - Similaridades"), closable = FALSE, width = 12, status = "white",
                                  solidHeader = TRUE, collapsible = TRUE, collapsed = TRUE,  maximizable = TRUE, 
                           fluidRow(column(4, infoBoxOutput("infobox_rel_sims1", width = 12)),
                                    column(4, infoBoxOutput("infobox_rel_sims2", width = 12)),
                                    column(4, infoBoxOutput("infobox_rel_sims3", width = 12))),
                           DT::dataTableOutput("table_rel_sims")))),
      
      bs4TabItem("menu_about", br(), uiOutput("sobre_projeto")))),
  footer = bs4DashFooter(left = "Aplicacção desenvolvida para XXVII Prêmio Tesouro Nacional 2022", right = HTML(paste(c("powered by ", "<b>", "OXYDATA", "</b>"))), fixed = FALSE))


server <- function(input, output, session) {
  
  ### Select Municipio
  
  output$escolha_mun <- renderUI({
    
    selectInput("escolha_mun","Selecione um município", choices = agg_municipios$nome_composto, selected = c("Itaobim  -  MG"))
    
  })

  observeEvent(input$sidebar, {
    if (input$sidebar) {
      shinyjs::show("escolha_mun")
    } else {
      shinyjs::hide("escolha_mun")
      
    }
  })
  

    
  ### Render Select Mun
  
  #### transferencias
  
  select_mun_transf <- reactive({ select_mun <- agg_municipios[agg_municipios$nome_composto==input$escolha_mun, c("codigo_ibge", "siafi_id", "uf_sigla", "nome", "nome_composto", "pib_per_capta", "pop_2021", "longitude", "latitude")]
  select_mun <- left_join(select_mun, 
                          preds_transf[preds_transf$codigo_ibge==select_mun$codigo_ibge, c("codigo_ibge", "candido_pred", "ranking_candido_pred", "xgb_pred", "lgbm_pred", "cb_pred")], 
                          by = "codigo_ibge")
  
  select_mun
  
  })
  
  select_mun_sims_transf <- reactive({ select_mun_sims <- data.frame("codigo_ibge" = t(similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge, -c(1:3)])[1:10])
  select_mun_sims <- left_join(select_mun_sims, 
                               agg_municipios[, c("codigo_ibge", "siafi_id", "uf_sigla", "nome", "nome_composto", "pib_per_capta", "pop_2021", "longitude", "latitude")], 
                               by = "codigo_ibge")
  select_mun_sims <- left_join(select_mun_sims, 
                               preds_transf[, c("codigo_ibge", "candido_pred", "ranking_candido_pred")], 
                               by = "codigo_ibge")
  select_mun_sims
  
  })
  
  select_estado_transf <- reactive({ select_estado <- left_join(agg_municipios[agg_municipios$uf_sigla==select_mun_transf()$uf_sigla, c("codigo_ibge", "siafi_id")], preds_transf[, c("codigo_ibge", "candido_pred")])

  select_estado
  
  })
  
  
  #### convenios
  
  select_mun_conv <- reactive({ select_mun <- agg_municipios[agg_municipios$nome_composto==input$escolha_mun, c("codigo_ibge", "siafi_id", "uf_sigla", "nome", "nome_composto", "pib_per_capta", "pop_2021", "longitude", "latitude")]
    select_mun <- left_join(select_mun, 
                            preds_convenios[preds_convenios$codigo_ibge==select_mun$codigo_ibge, c("codigo_ibge", "candido_pred_proba_1", "ranking_candido_pred_proba_1", "candido_pred_proba_1_min_desenv_reg", "candido_pred_proba_1_min_turismo",
                                                                                                   "candido_pred_proba_1_min_ciencia_tec_inov_comun", "candido_pred_proba_1_min_outros", "candido_pred_proba_1_min_mulher_fam_dh",
                                                                                                   "candido_pred_proba_1_min_saude", "candido_pred_proba_1_min_agri_pecu_abast", "candido_pred_proba_1_min_just_seg",
                                                                                                   "candido_pred_proba_1_min_educ", "candido_pred_proba_1_min_cidad", "candido_pred_proba_1_min_def")], 
                            by = "codigo_ibge")
    
    select_mun
    
    
    })
  
  select_mun_sims_conv <- reactive({ select_mun_sims <- data.frame("codigo_ibge" = t(similaridades[similaridades$codigo_ibge==select_mun_conv()$codigo_ibge, -c(1:3)])[1:10])
  select_mun_sims <- left_join(select_mun_sims, 
                               agg_municipios[, c("codigo_ibge", "siafi_id", "uf_sigla", "nome", "nome_composto", "pib_per_capta", "pop_2021", "longitude", "latitude")], 
                               by = "codigo_ibge")
  select_mun_sims <- left_join(select_mun_sims, 
                               preds_convenios[, c("codigo_ibge", "candido_pred_proba_1", "ranking_candido_pred_proba_1")], 
                               by = "codigo_ibge")
  select_mun_sims
  
  
  })
  
  select_estado_conv <- reactive({ select_estado <- left_join(agg_municipios[agg_municipios$uf_sigla==select_mun_conv()$uf_sigla, c("codigo_ibge", "siafi_id")], preds_convenios[, c("codigo_ibge", "candido_pred_proba_1")])
  
  select_estado
  
  })
  
  
  #### emendas
  
  select_mun_emendas <- reactive({ select_mun <- agg_municipios[agg_municipios$nome_composto==input$escolha_mun, c("codigo_ibge", "siafi_id", "uf_sigla","nome", "nome_composto", "pib_per_capta", "pop_2021", "longitude", "latitude")]
  select_mun <- left_join(select_mun, 
                          preds_emendas[preds_emendas$codigo_ibge==select_mun$codigo_ibge, c("codigo_ibge", "candido_pred_proba_1", "ranking_candido_pred_proba_1",
                                                                                             "candido_pred_proba_1_união",  "candido_pred_proba_1_republicanos",  "candido_pred_proba_1_pt",
                                                                                             "candido_pred_proba_1_psdb",  "candido_pred_proba_1_psd",  "candido_pred_proba_1_psb",  
                                                                                             "candido_pred_proba_1_pp",  "candido_pred_proba_1_pl", "candido_pred_proba_1_pdt",  "candido_pred_proba_1_outros",  
                                                                                             "candido_pred_proba_1_mdb")], 
                          by = "codigo_ibge")
  
  select_mun
  
  
  })
  
  select_mun_sims_emendas <- reactive({ select_mun_sims <- data.frame("codigo_ibge" = t(similaridades[similaridades$codigo_ibge==select_mun_emendas()$codigo_ibge, -c(1:3)])[1:10])
  select_mun_sims <- left_join(select_mun_sims, 
                               agg_municipios[, c("codigo_ibge", "siafi_id", "uf_sigla", "nome", "nome_composto", "pib_per_capta", "pop_2021", "longitude", "latitude")], 
                               by = "codigo_ibge")
  select_mun_sims <- left_join(select_mun_sims, 
                               preds_emendas[, c("codigo_ibge", "candido_pred_proba_1", "ranking_candido_pred_proba_1")], 
                               by = "codigo_ibge")
  select_mun_sims
  
  
  })
  
  select_estado_emendas <- reactive({ select_estado <- left_join(agg_municipios[agg_municipios$uf_sigla==select_mun_emendas()$uf_sigla, c("codigo_ibge", "siafi_id")], preds_emendas[, c("codigo_ibge", "candido_pred_proba_1")])
  
  select_estado
  
  })
  

  #### beneficios
  
  select_mun_beneficios <- reactive({ select_mun <- agg_municipios[agg_municipios$nome_composto==input$escolha_mun, c("codigo_ibge", "siafi_id", "uf_sigla", "nome", "nome_composto", "pib_per_capta", "pop_2021", "longitude", "latitude")]
  select_mun <- left_join(select_mun, 
                          preds_beneficios[preds_beneficios$codigo_ibge==select_mun$codigo_ibge, c("codigo_ibge", "candido_pred_geral_valor_per_capta", "ranking_candido_pred_geral_valor_per_capta",
                                                                                                   "candido_pred_proba_1_resid_garantia_safra_binario", "candido_pred_proba_1_resid_seguro_defeso_binario",
                                                                                                   "candido_pred_proba_1_resid_peti_binario", "candido_pred_resid_bpc_valor_per_capta",
                                                                                                   "candido_pred_resid_bolsa_familia_valor_per_capta")], 
                          by = "codigo_ibge")
  
  select_mun
  
  })
  
  select_mun_sims_beneficios <- reactive({ select_mun_sims <- data.frame("codigo_ibge" = t(similaridades[similaridades$codigo_ibge==select_mun_beneficios()$codigo_ibge, -c(1:3)])[1:10])
  select_mun_sims <- left_join(select_mun_sims, 
                               agg_municipios[, c("codigo_ibge", "siafi_id", "uf_sigla", "nome", "nome_composto", "pib_per_capta", "pop_2021", "longitude", "latitude")], 
                               by = "codigo_ibge")
  select_mun_sims <- left_join(select_mun_sims, 
                               preds_beneficios[, c("codigo_ibge", "candido_pred_geral_valor_per_capta", "ranking_candido_pred_geral_valor_per_capta")], 
                               by = "codigo_ibge")
  select_mun_sims
  
  
  })
  
  select_estado_beneficios <- reactive({ select_estado <- left_join(agg_municipios[agg_municipios$uf_sigla==select_mun_beneficios()$uf_sigla, c("codigo_ibge", "siafi_id")], preds_beneficios[, c("codigo_ibge", "candido_pred_geral_valor_per_capta")])
  
  select_estado
  
  })

  ### INFOBOX RENDER
  
  #### transferencias
  
  output$ibox_mun_transf <- renderbs4InfoBox({ bs4InfoBox(title = paste("TRANFERÊNCIAS - ", "Cod. IBGE: ", select_mun_transf()$codigo_ibge, "|", "SIAFI ID: ", select_mun_transf()$siafi_id), 
                                                        value = p(select_mun_transf()$nome_composto, style = "font-size: 170%;"),
                                                        icon = icon("city"), width = 12, iconElevation = 1) })
  
  
  output$ibox_pop_transf <- renderbs4InfoBox({ bs4InfoBox(title = "População - 2021", 
                                                        value = p(number_format(big.mark = ".")(select_mun_transf()$pop_2021), style = "font-size: 170%;"), 
                                                        icon = icon("user-friends"), width = 12, iconElevation = 1) })
  
  output$ibox_pib_transf <- renderbs4InfoBox({ bs4InfoBox(title = "PIB per capta - 2019", 
                                                        value = p(dollar_format(prefix = "R$")(select_mun_transf()$pib_per_capta), style = "font-size: 170%;"), 
                                                        icon = icon("dollar-sign"), width = 12, iconElevation = 1) })
  
  #### convenios
  
  output$ibox_mun_conv <- renderbs4InfoBox({ bs4InfoBox(title = paste("CONVÊNIOS - ", "Cod. IBGE: ", select_mun_conv()$codigo_ibge, "|", "SIAFI ID: ", select_mun_conv()$siafi_id), 
                                                   value = p(select_mun_conv()$nome_composto, style = "font-size: 170%;"),
                                                   icon = icon("city"), width = 12, iconElevation = 1) })
  
  
  output$ibox_pop_conv <- renderbs4InfoBox({ bs4InfoBox(title = "População - 2021", 
                                                   value = p(number_format(big.mark = ".")(select_mun_conv()$pop_2021), style = "font-size: 170%;"), 
                                                   icon = icon("user-friends"), width = 12, iconElevation = 1) })
  
  output$ibox_pib_conv <- renderbs4InfoBox({ bs4InfoBox(title = "PIB per capta - 2019", 
                                                   value = p(dollar_format(prefix = "R$")(select_mun_conv()$pib_per_capta), style = "font-size: 170%;"), 
                                                   icon = icon("dollar-sign"), width = 12, iconElevation = 1) })
  
  
  #### emendas
  
  output$ibox_mun_emendas <- renderbs4InfoBox({ bs4InfoBox(title = paste("EMENDAS PARLAMENTARES - ", "Cod. IBGE: ", select_mun_emendas()$codigo_ibge, "|", "SIAFI ID: ", select_mun_conv()$siafi_id), 
                                                        value = p(select_mun_conv()$nome_composto, style = "font-size: 170%;"),
                                                        icon = icon("city"), width = 12, iconElevation = 1) })
  
  
  output$ibox_pop_emendas <- renderbs4InfoBox({ bs4InfoBox(title = "População - 2021", 
                                                        value = p(number_format(big.mark = ".")(select_mun_emendas()$pop_2021), style = "font-size: 170%;"), 
                                                        icon = icon("user-friends"), width = 12, iconElevation = 1) })
  
  output$ibox_pib_emendas <- renderbs4InfoBox({ bs4InfoBox(title = "PIB per capta - 2019", 
                                                        value = p(dollar_format(prefix = "R$")(select_mun_emendas()$pib_per_capta), style = "font-size: 170%;"), 
                                                        icon = icon("dollar-sign"), width = 12, iconElevation = 1) })
  
  #### beneficios
  
  output$ibox_mun_benef <- renderbs4InfoBox({ bs4InfoBox(title = paste("BENEFÍCIOS CIDADÃO - ", "Cod. IBGE: ", select_mun_beneficios()$codigo_ibge, "|", "SIAFI ID: ", select_mun_conv()$siafi_id), 
                                                           value = p(select_mun_beneficios()$nome_composto, style = "font-size: 170%;"),
                                                           icon = icon("city"), width = 12, iconElevation = 1) })
  
  
  output$ibox_pop_benef <- renderbs4InfoBox({ bs4InfoBox(title = "População - 2021", 
                                                           value = p(number_format(big.mark = ".")(select_mun_beneficios()$pop_2021), style = "font-size: 170%;"), 
                                                           icon = icon("user-friends"), width = 12, iconElevation = 1) })
  
  output$ibox_pib_benef <- renderbs4InfoBox({ bs4InfoBox(title = "PIB per capta - 2019", 
                                                           value = p(dollar_format(prefix = "R$")(select_mun_beneficios()$pib_per_capta), style = "font-size: 170%;"), 
                                                           icon = icon("dollar-sign"), width = 12, iconElevation = 1) })
  
  
  
  ### VALUES BOX RENDER
  
  #### transf
  
  output$vbox_transf_candido <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(dollar_format(prefix = "R$")(select_mun_transf()$candido_pred), style = "font-size: 210%;")), 
                                                              p("Valor Per Capta - Total Transfer.", style = "font-size: 100%;"), width = 12, color = "olive", 
                                                              icon = icon("angle-double-up"), footer = "Município Selecionado") })
  
  output$vbox_transf_media_sims <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(dollar_format(prefix = "R$")(mean(select_mun_sims_transf()$candido_pred)), style = "font-size: 200%;")), 
                                                                 "Média - Valor Per Capta", width = 12, color = "gray", 
                                                                 icon("compress-alt"), footer = "Municípios Similares") })
  
  output$vbox_transf_media_estado <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(dollar_format(prefix = "R$")(mean(select_estado_transf()$candido_pred)), style = "font-size: 200%;")),    
                                                                     footer = paste("Municípios do Estado de", select_mun_transf()$uf_sigla),
                                                                     "Média - Valor Per Capta - Estadual", width = 12, color = "gray", icon("map-marker-alt")) })
  
  output$vbox_transf_ranking <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(select_mun_transf()$ranking_candido_pred, "º"), style = "font-size: 200%;")), 
                                                                p("Posição no Ranking - Brasil", style = "font-size: 100%;"), width = 12, color = "gray", 
                                                                icon = icon("list-ol"), footer = "Todos Municípios - Brasil")})
  
  
  #### conv
  
  output$vbox_conv_candido <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(round(select_mun_conv()$candido_pred_proba_1 * 100, 2), "%"), style = "font-size: 210%;")), 
                                                              p("Probab. Celebrar Convênio", style = "font-size: 100%;"), width = 12, color = "olive", 
                                                              icon = icon("angle-double-up"), footer = "Município Selecionado") })
  
  
  output$vbox_conv_media_sims <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(round(mean(select_mun_sims_conv()$candido_pred_proba_1) * 100, 2), "%"), style = "font-size: 200%;")), 
                                                                 "Média - Probab. Convênio", width = 12, color = "gray", 
                                                                 icon("compress-alt"), footer = "Municípios Similares") })
  
  
  output$vbox_conv_media_estado <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(round(mean(select_estado_conv()$candido_pred_proba_1) * 100, 2), "%"), style = "font-size: 200%;")),   
                                                                   "Média - Probab. Convênio - Estadual", width = 12, color = "gray", icon("map-marker-alt"),
                                                                   footer = paste("Municípios do Estado de", select_mun_conv()$uf_sigla)) })
  
  
  output$vbox_conv_ranking <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(select_mun_conv()$ranking_candido_pred_proba_1, "º"), style = "font-size: 200%;")), 
                                                              p("Posição no Ranking - Brasil", style = "font-size: 100%;"), width = 12, color = "gray", 
                                                              icon = icon("list-ol"), footer = "Todos Municípios - Brasil")})
  
  
  #### emendas
  
  output$vbox_emendas_candido <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(round(select_mun_emendas()$candido_pred_proba_1 * 100, 2), "%"), style = "font-size: 210%;")), 
                                                              p("Probab. Receber Emendas", style = "font-size: 100%;"), width = 12, color = "olive", 
                                                              icon = icon("angle-double-up"),  footer = "Município Selecionado") })
  
  output$vbox_emendas_media_sims <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(round(mean(select_mun_sims_emendas()$candido_pred_proba_1) * 100, 2), "%"), style = "font-size: 200%;")), 
                                                                    "Média - Probab. Emendas", width = 12, color = "gray", 
                                                                    icon("compress-alt"), footer = "Munincípios Similares") })
  
  output$vbox_emendas_media_estado <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(round(mean(select_estado_emendas()$candido_pred_proba_1) * 100, 2), "%"), style = "font-size: 200%;")),   
                                                                      "Média - Probab. Emendas - Estadual", width = 12, color = "gray", icon("map-marker-alt"),
                                                                      footer = paste("Municípios do Estado de", select_mun_emendas()$uf_sigla)) })
  
  output$vbox_emendas_ranking <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(select_mun_emendas()$ranking_candido_pred_proba_1, "º"), style = "font-size: 200%;")), 
                                                                 p("Posição no Ranking - Brasil", style = "font-size: 100%;"), width = 12, color = "gray", 
                                                                 icon = icon("list-ol"), footer = "Todos Municípios - Brasil")})

  
  #### beneficios
  
  output$vbox_benef_candido <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(dollar_format(prefix = "R$")(select_mun_beneficios()$candido_pred_geral_valor_per_capta), style = "font-size: 210%;")), 
                                                                 p("Valor Per Capta - Total Benefícios", style = "font-size: 100%;"), width = 12, color = "olive", 
                                                                 icon = icon("angle-double-up"),  footer = "Município Selecionado") })
  
  output$vbox_benef_media_sims <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(dollar_format(prefix = "R$")(mean(select_mun_sims_beneficios()$candido_pred_geral_valor_per_capta)), style = "font-size: 200%;")), 
                                                                    "Média - Valor Per Capta", width = 12, color = "gray", 
                                                                    icon("compress-alt"), footer = "Munincípios Similares") })
  
  output$vbox_benef_media_estado <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(dollar_format(prefix = "R$")(mean(select_estado_beneficios()$candido_pred_geral_valor_per_capta)), style = "font-size: 200%;")),  
                                                                    "Média - Valor Per Capta - Estadual", width = 12, color = "gray", icon("map-marker-alt"),
                                                                    footer = paste("Municípios do Estado de", select_mun_beneficios()$uf_sigla)) })
  
  output$vbox_benef_ranking <- renderbs4ValueBox({ bs4ValueBox(tags$b(p(paste(select_mun_beneficios()$ranking_candido_pred_geral_valor_per_capta, "º"), style = "font-size: 200%;")), 
                                                               p("Posição no Ranking - Brasil", style = "font-size: 100%;"), width = 12, color = "gray", 
                                                               icon = icon("list-ol"), footer = "Todos Municípios - Brasil")})
  
  
  ### CHARTS
  
  #### transferencias
  
  output$graf_transf_hist <- renderPlotly({
    
    fig <- plot_ly(x = preds_transf$candido_pred, type = "histogram", marker = list(color = 'gray'),  nbinsx = 300, opacity = 0.55, name = "Municípios") %>%
      add_lines(y = range(0, max(plot(cut(preds_transf$candido_pred, 300)))), x = select_mun_transf()$candido_pred, line = list(color = "green"), name = "Município Selecionado")  %>%
      add_lines(y = range(0, max(plot(cut(preds_transf$candido_pred, 300)))), x = mean(select_mun_sims_transf()$candido_pred), line = list(color = "#f3b501"), name = "Média - Munic. Similares") %>%
      add_lines(y = range(0, max(plot(cut(preds_transf$candido_pred, 300)))), x = mean(select_estado_transf()$candido_pred), line = list(color = "#0047f6"), name = "Média - Estado") %>% 
      layout(yaxis = list(title = 'Quantidade de Municípios'),
             xaxis = list(title = 'Valor per Capta - Transferências - #PredictCândido'),
             legend = list(x = 0.75, y = 0.95, title=list(text='<b> Legenda </b>')))
    fig
  
    }) 
  
  output$graf_transf_sims <- renderPlotly({
    
    fig <- plot_ly(x = select_mun_sims_transf()$candido_pred, y = paste(select_mun_sims_transf()$nome_composto, " "), type = "bar",
                   text = dollar_format(prefix = "R$")(select_mun_sims_transf()$candido_pred), textposition = 'auto', marker = list(color = '#d0d0d0')) %>%
      layout(xaxis = list(title = 'Valor per Capta - Transferências - #PredictCândido'),
             yaxis = list(title = "", 
                          categoryorder = "array",
                          categoryarray = select_mun_sims_transf()$nome_composto))
    fig
    
  }) 
  
  output$graf_transf_2021 <- renderPlotly({
    
    fig <- plot_ly(height=900, x = transferencias[transferencias$ano==2021 & transferencias$siafi_id == select_mun_transf()$siafi_id,]$valor_transf, 
                   y = paste(transferencias[transferencias$ano==2021 & transferencias$siafi_id == select_mun_transf()$siafi_id,]$linguagem_cidad, " "), 
                   type = "bar",
                   text = dollar_format(prefix = "R$")(transferencias[transferencias$ano==2021 & transferencias$siafi_id == select_mun_transf()$siafi_id,]$valor_transf), 
                   textposition = 'auto', marker = list(color = '#8fb687')) %>%
      layout(xaxis = list(title = 'Valor per Capta - Transferências - #PredictCândido'),
             yaxis = list(title = "",
                          categoryorder = "total ascending"))
    fig
    
  }) 
  
  
  #### convenios
  
  output$graf_conv_hist <- renderPlotly({
    
    fig <- plot_ly(x = preds_convenios$candido_pred_proba_1, type = "histogram", marker = list(color = 'gray'),  nbinsx = 300, opacity = 0.55, name = "Municípios") %>%
      add_lines(y = range(0, max(plot(cut(preds_convenios$candido_pred_proba_1, 250)))), x = select_mun_conv()$candido_pred_proba_1, line = list(color = "green"), name = "Município Selecionado")  %>%
      add_lines(y = range(0, max(plot(cut(preds_convenios$candido_pred_proba_1, 250)))), x = mean(select_mun_sims_conv()$candido_pred_proba_1), line = list(color = "#f3b501"), name = "Média - Munic. Similares") %>%
      add_lines(y = range(0, max(plot(cut(preds_convenios$candido_pred_proba_1, 250)))), x = mean(select_estado_conv()$candido_pred_proba_1), line = list(color = "#0047f6"), name = "Média - Estado") %>% 
      layout(yaxis = list(title = 'Quantidade de Municípios'),
             xaxis = list(title = 'Probabilidade - Convênios - #PredictCândido'),
             legend = list(x = 0.05, y = 0.95, title=list(text='<b> Legenda </b>')))
    fig
    
  }) 
  
  output$graf_conv_sims <- renderPlotly({
    
    fig <- plot_ly(x = select_mun_sims_conv()$candido_pred_proba_1, y = paste(select_mun_sims_conv()$nome_composto, " "), type = "bar",
                   text = paste(round(select_mun_sims_conv()$candido_pred_proba_1 * 100, 2), "%"), textposition = 'auto', marker = list(color = '#d0d0d0')) %>%
      layout(xaxis = list(title = 'Probabilidades - Convênios - #PredictCândido'),
             yaxis = list(title = "", 
                          categoryorder = "array",
                          categoryarray = select_mun_sims_conv()$nome_composto))
    fig
    
  }) 
  
  output$graf_conv_residual_mins <- renderPlotly({
    
    list_cols <- c("Min. Desenvolvimento Regional ", "Min. Turismo ", "Min. Ciência, Tecnologia e Inovações ", "Outros Ministérios ", "Min. Mulher, Família e Direitos Humanos ",
                   "Min. Saúde ", "Min. Agricultura, Pecuária e Abast. ", "Min. Justiça e Seg. Pública ", "Min. Educação ", "Min. das Cidades ")
    
    fig <- plot_ly(height = 900, y = list_cols, 
                   x = data.frame("probs" = t(select_mun_conv()[, c(12:21)]))[, "probs"], type = "bar",
                   text = paste(round(data.frame("probs" = t(select_mun_conv()[, c(12:21)]))[, "probs"] * 100, 2), "%"), textposition = 'auto', marker = list(color = '#8fb687')) %>%
      layout(xaxis = list(title = 'Probabilidades - Convênios - #PredictCândido'),
             yaxis = list(title = "",
                          categoryorder = "total ascending"))
    fig
    
  }) 
  
  #### emendas
  
  output$graf_emendas_hist <- renderPlotly({
    
    fig <- plot_ly(x = preds_emendas$candido_pred_proba_1, type = "histogram", marker = list(color = 'gray'),  nbinsx = 300, opacity = 0.55, name = "Municípios") %>%
      add_lines(y = range(0, max(plot(cut(preds_emendas$candido_pred_proba_1, 550)))), x = select_mun_emendas()$candido_pred_proba_1, line = list(color = "green"), name = "Município Selecionado")  %>%
      add_lines(y = range(0, max(plot(cut(preds_emendas$candido_pred_proba_1, 550)))), x = mean(select_mun_sims_emendas()$candido_pred_proba_1), line = list(color = "#f3b501"), name = "Média - Munic. Similares") %>%
      add_lines(y = range(0, max(plot(cut(preds_emendas$candido_pred_proba_1, 550)))), x = mean(select_estado_emendas()$candido_pred_proba_1), line = list(color = "#0047f6"), name = "Média - Estado") %>% 
      layout(yaxis = list(title = 'Quantidade de Municípios'),
             xaxis = list(title = 'Probabilidade - Emendas Parl. - #PredictCândido'),
             legend = list(x = 0.75, y = 0.95, title=list(text='<b> Legenda </b>')))
    fig
    
  }) 
  
  output$graf_emendas_sims <- renderPlotly({
    
    fig <- plot_ly(x = select_mun_sims_emendas()$candido_pred_proba_1, y = paste(select_mun_sims_emendas()$nome_composto, " "), type = "bar",
                   text = paste(round(select_mun_sims_emendas()$candido_pred_proba_1 * 100, 2), "%"), textposition = 'auto', marker = list(color = '#d0d0d0')) %>%
      layout(xaxis = list(title = 'Probabilidades - Emendas Parl. - #PredictCândido'),
             yaxis = list(title = "", 
                          categoryorder = "array",
                          categoryarray = select_mun_sims_emendas()$nome_composto))
    fig
    
  }) 
  
  output$graf_emendas_residual_mins <- renderPlotly({
    
    list_cols <- c("União Brasil ", "Republicanos ", "PT ", "PSDB ", "PSD ",
                   "PSB ", "PP ", "PL ", "PDT ", "Outros Partidos ", "MDB ")
    
    fig <- plot_ly(y = list_cols, 
                   x = data.frame("probs" = t(select_mun_emendas()[, c(12:22)]))[, "probs"], type = "bar",
                   text = paste(round(data.frame("probs" = t(select_mun_emendas()[, c(12:22)]))[, "probs"] * 100, 2), "%"), textposition = 'auto', marker = list(color = '#8fb687')) %>%
      layout(xaxis = list(title = 'Probabilidades - Emendas Parl. - #PredictCândido'),
             yaxis = list(title = "",
                          categoryorder = "total ascending"))
    fig
    
    
  }) 
  
  #### beneficios
  
  output$graf_beneficios_mensal <- renderPlotly({
    
    fig <- plot_ly(x = as.character(bolsa_familia[bolsa_familia$siafi_id==select_mun_beneficios()$siafi_id & order(bolsa_familia$ano_mes),]$ano_mes), 
                   y = bolsa_familia[bolsa_familia$siafi_id==select_mun_beneficios()$siafi_id & order(bolsa_familia$ano_mes),]$valor_parcela_agg, 
                   name = 'Bolsa Família', type = 'bar', marker = list(color = '#78b669'))
    
    if ( length(as.character(bpc[bpc$siafi_id == select_mun_beneficios()$siafi_id,]$ano_mes)) != 0 ) {
      
      fig <- fig %>% add_trace(x = as.character(bpc[bpc$siafi_id == select_mun_beneficios()$siafi_id,]$ano_mes), 
                               y = bpc[bpc$siafi_id == select_mun_beneficios()$siafi_id,]$valor_parcela_agg, name = 'BPC',  marker = list(color = '#e1d558'))
      
    }
    
    if ( length(as.character(seguro_defeso[seguro_defeso$siafi_id == select_mun_beneficios()$siafi_id,]$ano_mes)) != 0 ) {
      fig <- fig %>% add_trace(x = as.character(seguro_defeso[seguro_defeso$siafi_id == select_mun_beneficios()$siafi_id,]$ano_mes), 
                               y = seguro_defeso[seguro_defeso$siafi_id == select_mun_beneficios()$siafi_id,]$valor_parcela_agg, name = 'Seguro Defeso',  
                               marker = list(color = '#5399cf'))
    }
    
    if ( length(as.character(peti[peti$siafi_id == select_mun_beneficios()$siafi_id,]$ano_mes)) != 0 ) {
      
      fig <- fig %>% add_trace(x = as.character(peti[peti$siafi_id == select_mun_beneficios()$siafi_id,]$ano_mes), 
                               y = peti[peti$siafi_id == select_mun_beneficios()$siafi_id,]$valor_parcela_agg, name = 'PETI',  
                               marker = list(color = '#8f8f8f'))
    }
    
    if ( length(as.character(garantia_safra[garantia_safra$siafi_id == select_mun_beneficios()$siafi_id,]$ano_mes)) != 0 ) {
      
      fig <- fig %>% add_trace(x = as.character(garantia_safra[garantia_safra$siafi_id == select_mun_beneficios()$siafi_id,]$ano_mes), 
                               y = garantia_safra[garantia_safra$siafi_id == select_mun_beneficios()$siafi_id,]$valor_parcela_agg, name = 'Garantia-Safra',  
                               marker = list(color = '#cbcbcb'))
    }
    fig <- fig %>% layout(yaxis = list(title = 'Valor Total (R$)'), barmode = 'stack')
    
    fig
    
    
    
  }) 
  
  output$graf_beneficios_hist <- renderPlotly({
    
    fig <- plot_ly(x = preds_beneficios$candido_pred_geral_valor_per_capta, type = "histogram", marker = list(color = 'gray'),  nbinsx = 300, opacity = 0.55, name = "Municípios") %>%
      add_lines(y = range(0, max(plot(cut(preds_beneficios$candido_pred_geral_valor_per_capta, 200)))), x = select_mun_beneficios()$candido_pred_geral_valor_per_capta, line = list(color = "green"), name = "Município Selecionado")  %>%
      add_lines(y = range(0, max(plot(cut(preds_beneficios$candido_pred_geral_valor_per_capta, 200)))), x = mean(select_mun_sims_beneficios()$candido_pred_geral_valor_per_capta), line = list(color = "#f3b501"), name = "Média - Munic. Similares") %>%
      add_lines(y = range(0, max(plot(cut(preds_beneficios$candido_pred_geral_valor_per_capta, 200)))), x = mean(select_estado_beneficios()$candido_pred_geral_valor_per_capta), line = list(color = "#0047f6"), name = "Média - Estado") %>% 
      layout(yaxis = list(title = 'Quantidade de Municípios'),
             xaxis = list(title = 'Valor Per Capta - Benefícios - #PredictCândido'),
             legend = list(x = 0.75, y = 0.95, title=list(text='<b> Legenda </b>')))
    fig
    
  }) 
  
  output$graf_beneficios_sims <- renderPlotly({
    
    fig <- plot_ly(x = select_mun_sims_beneficios()$candido_pred_geral_valor_per_capta, y = paste(select_mun_sims_beneficios()$nome_composto, " "), type = "bar",
                   text = dollar_format(prefix = "R$")(select_mun_sims_beneficios()$candido_pred_geral_valor_per_capta), textposition = 'auto', marker = list(color = '#d0d0d0')) %>%
      layout(xaxis = list(title = 'Valor Per Capta - Benefícios Totais - #PredictCândido'),
             yaxis = list(title = "", 
                          categoryorder = "array",
                          categoryarray = select_mun_sims_beneficios()$nome_composto))
    fig
    
  }) 
  
  output$graf_beneficios_residual_probs <- renderPlotly({
    
    fig <- plot_ly(y = c("Garantia-Safra  ", "PETI  ", "Seguro Defeso  "), 
                   x = data.frame("probs" = t(preds_beneficios[preds_beneficios$codigo_ibge == select_mun_beneficios()$codigo_ibge, 
                                                               c("candido_pred_proba_1_resid_garantia_safra_binario",
                                                                 "candido_pred_proba_1_resid_peti_binario",
                                                                 "candido_pred_proba_1_resid_seguro_defeso_binario")]))[, c(1)],
                   text = paste(round(data.frame("probs" = t(preds_beneficios[preds_beneficios$codigo_ibge == select_mun_beneficios()$codigo_ibge, 
                                                                              c("candido_pred_proba_1_resid_garantia_safra_binario",
                                                                                "candido_pred_proba_1_resid_peti_binario",
                                                                                "candido_pred_proba_1_resid_seguro_defeso_binario")]))[, c(1)] * 100, 3), "%"),
                   type = "bar", marker = list(color = "#727272"))
    fig
    
  }) 
  
  output$graf_beneficios_residual_valor_per_capta <- renderPlotly({
    
    fig <- plot_ly(y = c("Bolsa Família  ", "BPC  "), x = t(preds_beneficios[preds_beneficios$codigo_ibge == select_mun_beneficios()$codigo_ibge, 
                                                                             c("candido_pred_resid_bolsa_familia_valor_per_capta",
                                                                               "candido_pred_resid_bpc_valor_per_capta")])[, c(1)],
                   text = dollar_format(prefix = "R$")(t(preds_beneficios[preds_beneficios$codigo_ibge == select_mun_beneficios()$codigo_ibge, 
                                                                          c("candido_pred_resid_bolsa_familia_valor_per_capta",
                                                                            "candido_pred_resid_bpc_valor_per_capta")])[, c(1)]),
                   type = "bar", marker = list(color = "#727272"))
    fig
    
    
  }) 
  
  
  ### TABLES
  
  #### RANKING
  
  #### transferencias
  
  output$table_transf_top10 <- DT::renderDataTable(server = FALSE,{
    
    df_top10_map <- merge(agg_municipios[agg_municipios$uf_sigla==select_mun_transf()$uf_sigla, c("codigo_ibge", "nome_composto")], 
                          preds_transf[, c("codigo_ibge", "candido_pred", "ranking_candido_pred")], by = c("codigo_ibge"))
    df_top10_map <- head(df_top10_map[order(df_top10_map$ranking_candido_pred, decreasing = FALSE) ,], 5)
    rownames(df_top10_map) <- 1:nrow(df_top10_map)
    
    if (select_mun_transf()$codigo_ibge %in% df_top10_map$codigo_ibge) {
      
      datatable(df_top10_map, colnames = c('Cód. IBGE', 'Nome - Mun.', 'Transf - Valor Per Capta', 'Posição - Ranking - Nacional'),
                rownames = FALSE, options = list(dom = 't', 
                                                 columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(3, currency = "R$") %>% formatStyle(0, target = "row", fontWeight = styleRow(rownames(df_top10_map[df_top10_map$codigo_ibge==select_mun_transf()$codigo_ibge,]), "bold"))
      
    } else {
      
      new_row <- merge(agg_municipios[agg_municipios$codigo_ibge==select_mun_transf()$codigo_ibge, c("codigo_ibge", "nome_composto")],
                       preds_transf[, c("codigo_ibge", "candido_pred", "ranking_candido_pred")], by = c("codigo_ibge"))
      
      datatable(rbind(head(df_top10_map, 4), new_row), colnames = c('Cód. IBGE', 'Nome - Mun.', 'Transf - Valor Per Capta', 'Posição - Ranking - Nacional'),
                rownames = FALSE, options = list(dom = 't',
                                                 columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(3, currency = "R$")  %>% formatStyle(0, target = "row", fontWeight = styleRow(5, "bold"))
      
      
    }
    
  }) 
  
  #### benef
  
  output$table_benef_top10 <- DT::renderDataTable(server = FALSE,{
    
    df_top10_map <- merge(agg_municipios[agg_municipios$uf_sigla==select_mun_beneficios()$uf_sigla, c("codigo_ibge", "nome_composto")], 
                          preds_beneficios[, c("codigo_ibge", "candido_pred_geral_valor_per_capta", 
                                               "ranking_candido_pred_geral_valor_per_capta")], by = c("codigo_ibge"))
    df_top10_map <- head(df_top10_map[order(df_top10_map$ranking_candido_pred_geral_valor_per_capta, decreasing = FALSE) ,], 5)
    rownames(df_top10_map) <- 1:nrow(df_top10_map)
    
    if (select_mun_beneficios()$codigo_ibge %in% df_top10_map$codigo_ibge) {
      
      datatable(df_top10_map, colnames = c('Cód. IBGE', 'Nome - Mun.', 'Benef. - Valor Per Capta', 'Posição - Ranking - Nacional'),
                rownames = FALSE, options = list(dom = 't', 
                                                 columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(3, currency = "R$") %>% formatStyle(0, target = "row", fontWeight = styleRow(rownames(df_top10_map[df_top10_map$codigo_ibge==select_mun_beneficios()$codigo_ibge,]), "bold"))
      
    } else {
      
      new_row <- merge(agg_municipios[agg_municipios$codigo_ibge==select_mun_beneficios()$codigo_ibge, c("codigo_ibge", "nome_composto")],
                       preds_beneficios[, c("codigo_ibge", "candido_pred_geral_valor_per_capta", 
                                        "ranking_candido_pred_geral_valor_per_capta")], by = c("codigo_ibge"))
      
      datatable(rbind(head(df_top10_map, 4), new_row), colnames = c('Cód. IBGE', 'Nome - Mun.', 'Benef. - Valor Per Capta', 'Posição - Ranking - Nacional'),
                rownames = FALSE, options = list(dom = 't',
                                                 columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(3, currency = "R$")  %>% formatStyle(0, target = "row", fontWeight = styleRow(5, "bold"))
      
      
    }
    
  }) 
  
  ### conv
  
  output$table_conv_top10 <- DT::renderDataTable(server = FALSE,{
    
    df_top10_map <- merge(agg_municipios[agg_municipios$uf_sigla==select_mun_conv()$uf_sigla, c("codigo_ibge", "nome_composto")], 
                          preds_convenios[, c("codigo_ibge", "candido_pred_proba_1", 
                                              "ranking_candido_pred_proba_1")], by = c("codigo_ibge"))
    df_top10_map <- head(df_top10_map[order(df_top10_map$ranking_candido_pred_proba_1, decreasing = FALSE) ,], 5)
    rownames(df_top10_map) <- 1:nrow(df_top10_map)
    
    if (select_mun_conv()$codigo_ibge %in% df_top10_map$codigo_ibge) {
      
      datatable(df_top10_map, colnames = c('Cód. IBGE', 'Nome - Mun.', 'Convênios - Probab.', 'Posição - Ranking - Nacional'),
                rownames = FALSE, options = list(dom = 't', 
                                                 columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatPercentage(c('candido_pred_proba_1'), 2) %>%  formatStyle(0, target = "row", fontWeight = styleRow(rownames(df_top10_map[df_top10_map$codigo_ibge==select_mun_conv()$codigo_ibge,]), "bold"))
      
    } else {
      
      new_row <- merge(agg_municipios[agg_municipios$codigo_ibge==select_mun_conv()$codigo_ibge, c("codigo_ibge", "nome_composto")],
                       preds_convenios[, c("codigo_ibge", "candido_pred_proba_1", 
                                        "ranking_candido_pred_proba_1")], by = c("codigo_ibge"))
      
      datatable(rbind(head(df_top10_map, 4), new_row), colnames = c('Cód. IBGE', 'Nome - Mun.', 'Convênios - Probab.', 'Posição - Ranking - Nacional'),
                rownames = FALSE, options = list(dom = 't',
                                                 columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatPercentage(c('candido_pred_proba_1'), 2) %>% formatStyle(0, target = "row", fontWeight = styleRow(5, "bold"))
      
      
    }
    
  }) 
  
  ### emendas
  
  output$table_emendas_top10 <- DT::renderDataTable(server = FALSE,{
    
    df_top10_map <- merge(agg_municipios[agg_municipios$uf_sigla==select_mun_emendas()$uf_sigla, c("codigo_ibge", "nome_composto")], 
                          preds_emendas[, c("codigo_ibge",  "candido_pred_proba_1", 
                                           "ranking_candido_pred_proba_1")], by = c("codigo_ibge"))
    df_top10_map <- head(df_top10_map[order(df_top10_map$ranking_candido_pred_proba_1, decreasing = FALSE) ,], 5)
    rownames(df_top10_map) <- 1:nrow(df_top10_map)
    
    if (select_mun_emendas()$codigo_ibge %in% df_top10_map$codigo_ibge) {
      
      datatable(df_top10_map, colnames = c('Cód. IBGE', 'Nome - Mun.', 'Emendas - Probab.', 'Posição - Ranking - Nacional'),
                rownames = FALSE, options = list(dom = 't', 
                                                 columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatPercentage(c('candido_pred_proba_1'), 2) %>% formatStyle(0, target = "row", fontWeight = styleRow(rownames(df_top10_map[df_top10_map$codigo_ibge==select_mun_emendas()$codigo_ibge,]), "bold"))
      
    } else {
      
      new_row <- merge(agg_municipios[agg_municipios$codigo_ibge==select_mun_emendas()$codigo_ibge, c("codigo_ibge", "nome_composto")],
                       preds_emendas[, c("codigo_ibge", "candido_pred_proba_1", 
                                        "ranking_candido_pred_proba_1")], by = c("codigo_ibge"))
      
      datatable(rbind(head(df_top10_map, 4), new_row), colnames = c('Cód. IBGE', 'Nome - Mun.', 'Emendas - Probab.', 'Posição - Ranking - Nacional'),
                rownames = FALSE, options = list(dom = 't',
                                                 columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatPercentage(c('candido_pred_proba_1'), 2) %>% formatStyle(0, target = "row", fontWeight = styleRow(5, "bold"))
      
      
    }
    
  }) 
  
  #### DADOS COMPLETOS
  
  #### transferencias
 
  output$table_transferencias <- DT::renderDataTable(server = FALSE,{
    datatable(transferencias[transferencias$siafi_id==select_mun_transf()$siafi_id,],  extensions = 'Buttons',
              rownames = FALSE, options = list(order = list(list(1, 'desc'), list(3, 'desc')), buttons = c('csv', 'excel'), 
                                              scrollX = T, dom = 'lBfrtip', columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(4, currency = "R$")
      
  }) 
  
  #### convenios
  
  output$table_convenios <- DT::renderDataTable(server = FALSE,{
    
    con <- dbConnect(RSQLite::SQLite(), "data/data.db")
    
    convenios <- dbGetQuery(con, paste0("SELECT * FROM convenios WHERE `CÓDIGO SIAFI MUNICÍPIO` == ", select_mun_conv()$siafi_id))
    
    dbDisconnect(con)
      
    datatable(convenios,  extensions = 'Buttons',
              rownames = FALSE, options = list(order = list(list(4, 'desc')), buttons = c('csv', 'excel'), 
                                               autoWidth = TRUE, scrollX = T, dom = 'lBfrtip', columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(13:14, currency = "R$")
    
    
  }) 
  
  #### emendas
  
  output$table_emendas <- DT::renderDataTable(server = FALSE,{
    datatable(emendas[emendas$Código.IBGE.Município==select_mun_emendas()$codigo_ibge,],  extensions = 'Buttons',
              rownames = FALSE, options = list(order = list(list(6, 'desc')), buttons = c('csv', 'excel'), 
                                               scrollX = T, dom = 'lBfrtip', columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(11:13, currency = "R$")
    
  }) 
  
  #### beneficios
  
  ##### bolsa familia
  
  output$table_benef_bolsa_familia <- DT::renderDataTable(server = FALSE,{
    datatable(bolsa_familia[bolsa_familia$siafi_id==select_mun_beneficios()$siafi_id,],  extensions = 'Buttons',
              rownames = FALSE, options = list(order = list(list(0, 'desc')), buttons = c('csv', 'excel'), 
                                              scrollX = T, dom = 'lBfrtip', columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(4, currency = "R$")
    
  }) 
  
  output$table_benef_bpc <- DT::renderDataTable(server = FALSE,{
    datatable(bpc[bpc$siafi_id==select_mun_beneficios()$siafi_id,],  extensions = 'Buttons',
              rownames = FALSE, options = list(order = list(list(0, 'desc')), buttons = c('csv', 'excel'), 
                                              scrollX = T, dom = 'lBfrtip', columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(4, currency = "R$")
    
  }) 
  
  output$table_benef_garantia_safra <- DT::renderDataTable(server = FALSE,{
    datatable(garantia_safra[garantia_safra$siafi_id==select_mun_beneficios()$siafi_id,],  extensions = 'Buttons',
              rownames = FALSE, options = list(order = list(list(0, 'desc')), buttons = c('csv', 'excel'), 
                                               scrollX = T, dom = 'lBfrtip', columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(4, currency = "R$")
    
  }) 
  
  
  output$table_benef_seguro_defeso <- DT::renderDataTable(server = FALSE,{
    datatable(seguro_defeso[seguro_defeso$siafi_id==select_mun_beneficios()$siafi_id,],  extensions = 'Buttons',
              rownames = FALSE, options = list(order = list(list(0, 'desc')), buttons = c('csv', 'excel'), 
                                               scrollX = T, dom = 'lBfrtip', columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(4, currency = "R$")
    
  }) 
  
  output$table_benef_peti <- DT::renderDataTable(server = FALSE,{
    datatable(peti[peti$siafi_id==select_mun_beneficios()$siafi_id,],  extensions = 'Buttons',
              rownames = FALSE, options = list(order = list(list(0, 'desc')), buttons = c('csv', 'excel'), 
                                              scrollX = T, dom = 'lBfrtip', columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(4, currency = "R$")
    
  }) 
  
  
  ## CANDIDO
  
  ### transferencias 
  
  output$vbox_rel_transf_xgb <- renderbs4ValueBox({
    bs4ValueBox(
      value = tags$b(p(dollar_format(prefix = "R$")(select_mun_transf()$xgb_pred), style = "font-size: 210%;")),
      subtitle = paste("XGBoost - Decisão |", select_mun_transf()$nome_composto),
      color = "gray",
      width = 12,
      href = "https://xgboost.readthedocs.io/en/stable/"
    )
  })
  
  output$vbox_rel_transf_lgbm <- renderbs4ValueBox({
    bs4ValueBox(
      value =  tags$b(p(dollar_format(prefix = "R$")(select_mun_transf()$lgbm_pred), style = "font-size: 210%;")),
      subtitle = paste("LightGBM - Decisão |", select_mun_transf()$nome_composto),
      color = "gray",
      width = 12,
      href = "https://lightgbm.readthedocs.io/en/v3.3.3/"
    )
  })
  
  output$vbox_rel_transf_cb <- renderbs4ValueBox({
    bs4ValueBox(
      value = tags$b(p(dollar_format(prefix = "R$")(select_mun_transf()$cb_pred), style = "font-size: 210%;")),
      subtitle = paste("CatBoost - Decisão |", select_mun_transf()$nome_composto),
      color = "gray",
      width = 12,
      href = "https://catboost.ai/"
    )
  })
  
  output$vbox_rel_transf_candido <- renderbs4ValueBox({
    bs4ValueBox(
      value = tags$b(p(dollar_format(prefix = "R$")(select_mun_transf()$candido_pred), style = "font-size: 210%;")),
      subtitle = paste("Cândido - Ensemble |", select_mun_transf()$nome_composto),
      color = "olive",
      width = 12,
      href = "https://en.wikipedia.org/wiki/Ensemble_learning"
    )
  })
  
  #### graficos
  
  output$plot_rel_transf_r2 <- renderPlot({
    
    data <- data.frame(
      Algoritmo = performance_mdl_reg[performance_mdl_reg$Tema=="Transferências", c("Algoritmo")],  
      Valor = performance_mdl_reg[performance_mdl_reg$Tema=="Transferências", c("R2")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="R2", x ="Valor", y = "")
    p 
    
  })
  
  output$plot_rel_transf_mse <- renderPlot({
    
    data <- data.frame(
      Algoritmo = performance_mdl_reg[performance_mdl_reg$Tema=="Transferências", c("Algoritmo")],  
      Valor = performance_mdl_reg[performance_mdl_reg$Tema=="Transferências", c("MSE")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 2)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="MSE", x ="Valor", y = "")
    p 
    
  })
  
  output$plot_rel_transf_rmse <- renderPlot({
    
    data <- data.frame(
      Algoritmo = performance_mdl_reg[performance_mdl_reg$Tema=="Transferências", c("Algoritmo")],  
      Valor = performance_mdl_reg[performance_mdl_reg$Tema=="Transferências", c("RMSE")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 2)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="RMSE", x ="Valor", y = "")
    p 
    
  })
  
  
  
  #### table relat transf
  
  output$table_rel_transf <- DT::renderDataTable(server = FALSE,{
    datatable(preds_transf,  extensions = 'Buttons', rownames = FALSE, 
              options = list(buttons = c('csv', 'excel'), scrollX = T, dom = 'lBfrtip', 
                             columnDefs = list(list(className = 'dt-center', targets = "_all")))) %>% formatCurrency(4:7, currency = "R$")
    
  }) 
  
  
  ### convenios
  
  output$select_rel_conv <- renderUI({
    
    selectInput("select_rel_conv", "Selecione o órgão do modelo:",
                c("Geral" = "Geral",
                  "Ministério do Desenvolvimento Regional" = "min_desenv_reg",
                  "Ministério do Turismo" = "min_turismo",
                  "Ministério da Ciência, Tecnologia e Inovação" = "min_ciencia_tec_inov_comun",
                  "Ministério da Mulher, Família e Direitos Humanos" = "min_mulher_fam_dh",
                  "Ministério da Saúde" = "min_saude",
                  "Ministério da Agricultura, Pecuária e Abastecimento" = "min_agri_pecu_abast",
                  "Ministério da Justiça e Segurança Pública" = "min_just_seg",
                  "Ministério da Educação" = "min_educ",
                  "Ministério da Cidadania" = "min_cidad",
                  "Ministério da Defesa" = "min_def",
                  "Outros Ministérios" = "min_outros"
                ))
    
    
  })
  

  output$vbox_rel_conv_xgb <- renderbs4ValueBox({
    bs4ValueBox(
      value = tags$b(p(paste(round(preds_convenios[preds_convenios$codigo_ibge==select_mun_conv()$codigo_ibge, c( ifelse(input$select_rel_conv == "Geral", "xgb_proba_1", paste0("xgb_proba_1_", input$select_rel_conv)))] * 100, 2), "%"), style = "font-size: 210%;")),
      subtitle = paste("XGBoost - Decisão |", select_mun_conv()$nome_composto),
      color = "gray",
      width = 12,
      href = "https://xgboost.readthedocs.io/en/stable/"
    )
  })
  
  
  output$vbox_rel_conv_lgbm <- renderbs4ValueBox({
    bs4ValueBox(
      value =  tags$b(p(paste(round(preds_convenios[preds_convenios$codigo_ibge==select_mun_conv()$codigo_ibge, c(ifelse(input$select_rel_conv == "Geral", "lgbm_proba_1", paste0("lgbm_proba_1_", input$select_rel_conv)))]* 100, 2), "%"), style = "font-size: 210%;")),
      subtitle = paste("LightGBM - Decisão |", select_mun_conv()$nome_composto),
      color = "gray",
      width = 12,
      href = "https://lightgbm.readthedocs.io/en/v3.3.3/"
    )
  })
  
  output$vbox_rel_conv_cb <- renderbs4ValueBox({
    bs4ValueBox(
      value = tags$b(p(paste(round(preds_convenios[preds_convenios$codigo_ibge==select_mun_conv()$codigo_ibge, c(ifelse(input$select_rel_conv == "Geral", "cb_proba_1", paste0("cb_proba_1_", input$select_rel_conv)))] * 100, 2), "%"), style = "font-size: 210%;")),
      subtitle = paste("CatBoost - Decisão |", select_mun_conv()$nome_composto),
      color = "gray",
      width = 12,
      href = "https://catboost.ai/"
    )
  })
  
  output$vbox_rel_conv_candido <- renderbs4ValueBox({
    bs4ValueBox(
      value = tags$b(p(paste(round(preds_convenios[preds_convenios$codigo_ibge==select_mun_conv()$codigo_ibge, c(ifelse(input$select_rel_conv == "Geral", "candido_pred_proba_1", paste0("candido_pred_proba_1_", input$select_rel_conv)))] * 100, 2), "%"), style = "font-size: 210%;")),
      subtitle = paste("Cândido - Ensemble |", select_mun_conv()$nome_composto),
      color = "olive",
      width = 12,
      href = "https://en.wikipedia.org/wiki/Ensemble_learning"
    )
  })
  
 
  output$plot_rel_conv_acc <- renderPlot({
    
    data <- data.frame(
      Algoritmo = performance_mdl[performance_mdl$Tema=="Convênios" & performance_mdl$Área == input$select_rel_conv, c("Algoritmo")],  
      Valor = performance_mdl[performance_mdl$Tema=="Convênios" & performance_mdl$Área == input$select_rel_conv, c("Accuracy")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="Accuracy", x ="Valor", y = "")
    p 
    
  })
  
  output$plot_rel_conv_roc_auc <- renderPlot({
    
    data <- data.frame(
      Algoritmo = performance_mdl[performance_mdl$Tema=="Convênios" & performance_mdl$Área == input$select_rel_conv, c("Algoritmo")],  
      Valor = performance_mdl[performance_mdl$Tema=="Convênios" & performance_mdl$Área == input$select_rel_conv, c("ROC_AUC")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="ROC-AUC", x ="Valor", y = "")
    p 
    
  })
  
  output$plot_rel_conv_log_loss <- renderPlot({
    
    data <- data.frame(
      Algoritmo = performance_mdl[performance_mdl$Tema=="Convênios" & performance_mdl$Área == input$select_rel_conv, c("Algoritmo")],  
      Valor = performance_mdl[performance_mdl$Tema=="Convênios" & performance_mdl$Área == input$select_rel_conv, c("Log_Loss")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="Log Loss", x ="Valor", y = "")
    p 
    
  })
  
  
  output$table_rel_conv <- DT::renderDataTable(server = FALSE,{
    
    if (input$select_rel_conv == "Geral") {
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1", "lgbm_proba_1", "cb_proba_1", "candido_pred_proba_1", "candido_pred")
    } else if (input$select_rel_conv == "min_desenv_reg") {
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_desenv_reg", "lgbm_proba_1_min_desenv_reg", "cb_proba_1_min_desenv_reg", 
                            "candido_pred_proba_1_min_desenv_reg")
    } else if (input$select_rel_conv == "min_turismo") {
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_turismo", "lgbm_proba_1_min_turismo", "cb_proba_1_min_turismo", 
                            "candido_pred_proba_1_min_turismo")
    } else if (input$select_rel_conv == "min_ciencia_tec_inov_comun"){
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_ciencia_tec_inov_comun", "lgbm_proba_1_min_ciencia_tec_inov_comun", 
                            "cb_proba_1_min_ciencia_tec_inov_comun", "candido_pred_proba_1_min_ciencia_tec_inov_comun")
    } else if (input$select_rel_conv == "min_outros") {
      
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_ciencia_tec_inov_comun", "lgbm_proba_1_min_ciencia_tec_inov_comun", 
                            "cb_proba_1_min_ciencia_tec_inov_comun", "candido_pred_proba_1_min_ciencia_tec_inov_comun")
      
    } else if (input$select_rel_conv == "min_mulher_fam_dh") {
      
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_mulher_fam_dh", "lgbm_proba_1_min_mulher_fam_dh", 
                            "cb_proba_1_min_mulher_fam_dh", "candido_pred_proba_1_min_mulher_fam_dh")
      
    } else if (input$select_rel_conv == "min_saude") {
      
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_saude", "lgbm_proba_1_min_saude", 
                            "cb_proba_1_min_saude", "candido_pred_proba_1_min_saude")
      
    } else if (input$select_rel_conv == "min_agri_pecu_abast") {
      
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_agri_pecu_abast", "lgbm_proba_1_min_agri_pecu_abast", 
                            "cb_proba_1_min_agri_pecu_abast", "candido_pred_proba_1_min_agri_pecu_abast")
      
    } else if (input$select_rel_conv == "min_just_seg") {
      
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_just_seg", "lgbm_proba_1_min_just_seg", 
                            "cb_proba_1_min_just_seg", "candido_pred_proba_1_min_just_seg")
      
    } else if (input$select_rel_conv == "min_educ") {
      
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_educ", "lgbm_proba_1_min_educ", 
                            "cb_proba_1_min_educ", "candido_pred_proba_1_min_educ")
      
    } else if (input$select_rel_conv == "min_cidad") {
      
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_cidad", "lgbm_proba_1_min_cidad", 
                            "cb_proba_1_min_cidad", "candido_pred_proba_1_min_cidad")
      
    } else if (input$select_rel_conv == "min_def") {
      
      select_cols_conv <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_min_def", "lgbm_proba_1_min_def", 
                            "cb_proba_1_min_def", "candido_pred_proba_1_min_def")
      
    }
    
    
    datatable(preds_convenios[, select_cols_conv],  extensions = 'Buttons', rownames = FALSE, 
              options = list(buttons = c('csv', 'excel'), scrollX = T, dom = 'lBfrtip', 
                             columnDefs = list(list(className = 'dt-center', targets = "_all"))))
    
  })
  
  ### emendas
  
  output$select_rel_emendas <- renderUI({
  
  selectInput("select_rel_emendas", "Selecione o partido do modelo:",
              c("Geral" = "Geral",
                "União Brasil" = "união",
                "Republicanos" = "republicanos",
                "PT" = "pt",
                "PSDB" = "psdb",
                "PSD" = "psd",
                "PSB" = "psb",
                "PP" = "pp",
                "PL" = "pl",
                "PDT" = "pdt",
                "MDB" = "mdb",
                "Outros Partidos" = "outros"
              ))
    
  })
  

  output$vbox_rel_emendas_xgb <- renderbs4ValueBox({
    bs4ValueBox(
      value = tags$b(p(paste(round(preds_emendas[preds_emendas$codigo_ibge==select_mun_emendas()$codigo_ibge, c(ifelse(input$select_rel_emendas == "Geral", "xgb_proba_1", paste0("xgb_proba_1_", input$select_rel_emendas)))] * 100, 2), "%"), style = "font-size: 210%;")),
      subtitle = paste("XGBoost - Decisão |", select_mun_emendas()$nome_composto),
      color = "gray",
      width = 12,
      href = "https://xgboost.readthedocs.io/en/stable/"
    )
  })
  
  
  output$vbox_rel_emendas_lgbm <- renderbs4ValueBox({
    bs4ValueBox(
      value =  tags$b(p(paste(round(preds_emendas[preds_emendas$codigo_ibge==select_mun_emendas()$codigo_ibge, c(ifelse(input$select_rel_emendas == "Geral", "lgbm_proba_1", paste0("lgbm_proba_1_", input$select_rel_emendas)))]* 100, 2), "%"), style = "font-size: 210%;")),
      subtitle = paste("LightGBM - Decisão |", select_mun_emendas()$nome_composto),
      color = "gray",
      width = 12,
      href = "https://lightgbm.readthedocs.io/en/v3.3.3/"
    )
  })
  
  output$vbox_rel_emendas_cb <- renderbs4ValueBox({
    bs4ValueBox(
      value = tags$b(p(paste(round(preds_emendas[preds_emendas$codigo_ibge==select_mun_emendas()$codigo_ibge, c(ifelse(input$select_rel_emendas == "Geral", "cb_proba_1", paste0("cb_proba_1_", input$select_rel_emendas)))] * 100, 2), "%"), style = "font-size: 210%;")),
      subtitle = paste("CatBoost - Decisão |", select_mun_emendas()$nome_composto),
      color = "gray",
      width = 12,
      href = "https://catboost.ai/"
    )
  })
  
  output$vbox_rel_emendas_candido <- renderbs4ValueBox({
    bs4ValueBox(
      value = tags$b(p(paste(round(preds_emendas[preds_emendas$codigo_ibge==select_mun_emendas()$codigo_ibge, c(ifelse(input$select_rel_emendas == "Geral", "candido_pred_proba_1", paste0("candido_pred_proba_1_", input$select_rel_emendas)))] * 100, 2), "%"), style = "font-size: 210%;")),
      subtitle = paste("Cândido - Ensemble |", select_mun_emendas()$nome_composto),
      color = "olive",
      width = 12,
      href = "https://en.wikipedia.org/wiki/Ensemble_learning"
    )
  })
  
  
  output$plot_rel_emendas_acc <- renderPlot({
    
    data <- data.frame(
      Algoritmo = performance_mdl[performance_mdl$Tema=="Emendas" & performance_mdl$Área == input$select_rel_emendas, c("Algoritmo")],  
      Valor = performance_mdl[performance_mdl$Tema=="Emendas" & performance_mdl$Área == input$select_rel_emendas, c("Accuracy")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="Accuracy", x ="Valor", y = "")
    p 
    
  })
  
  output$plot_rel_emendas_roc_auc <- renderPlot({
    
    data <- data.frame(
      Algoritmo = performance_mdl[performance_mdl$Tema=="Emendas" & performance_mdl$Área == input$select_rel_emendas, c("Algoritmo")],  
      Valor = performance_mdl[performance_mdl$Tema=="Emendas" & performance_mdl$Área == input$select_rel_emendas, c("ROC_AUC")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="ROC-AUC", x ="Valor", y = "")
    p 
    
  })
  
  output$plot_rel_emendas_log_loss <- renderPlot({
    
    data <- data.frame(
      Algoritmo = performance_mdl[performance_mdl$Tema=="Emendas" & performance_mdl$Área == input$select_rel_emendas, c("Algoritmo")],  
      Valor = performance_mdl[performance_mdl$Tema=="Emendas" & performance_mdl$Área == input$select_rel_emendas, c("Log_Loss")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="Log Loss", x ="Valor", y = "")
    p 
    
  })
  
  
    
    output$table_rel_emendas <- DT::renderDataTable(server = FALSE,{
      
      if (input$select_rel_emendas == "Geral") {
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1", "lgbm_proba_1", "cb_proba_1", "candido_pred_proba_1", "candido_pred")
      } else if (input$select_rel_emendas == "união") {
        
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_união", "lgbm_proba_1_união", "cb_proba_1_união", 
                              "candido_pred_proba_1_união")
      } else if (input$select_rel_emendas == "republicanos") {
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_republicanos", "lgbm_proba_1_republicanos", "cb_proba_1_republicanos", 
                                 "candido_pred_proba_1_republicanos")
      } else if (input$select_rel_emendas == "pt"){
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_pt", "lgbm_proba_1_pt", 
                              "cb_proba_1_pt", "candido_pred_proba_1_pt")
      } else if (input$select_rel_emendas == "psdb") {
        
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_psdb", "lgbm_proba_1_psdb", 
                              "cb_proba_1_psdb", "candido_pred_proba_1_psdb")
        
      } else if (input$select_rel_emendas == "psd") {
        
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_psd", "lgbm_proba_1_psd", 
                              "cb_proba_1_psd", "candido_pred_proba_1_psd")
        
      } else if (input$select_rel_emendas == "pp") {
        
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_pp", "lgbm_proba_1_pp", 
                              "cb_proba_1_pp", "candido_pred_proba_1_pp")
        
      } else if (input$select_rel_emendas == "psb") {
        
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_psb", "lgbm_proba_1_psb", 
                                 "cb_proba_1_psb", "candido_pred_proba_1_psb")
        
      } else if (input$select_rel_emendas == "pl") {
        
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_pl", "lgbm_proba_1_pl", 
                              "cb_proba_1_pl", "candido_pred_proba_1_pl")
        
      } else if (input$select_rel_emendas == "pdt") {
        
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_pdt", "lgbm_proba_1_pdt", 
                              "cb_proba_1_pdt", "candido_pred_proba_1_pdt")
        
      } else if (input$select_rel_emendas == "mdb") {
        
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_mdb", "lgbm_proba_1_mdb", 
                              "cb_proba_1_mdb", "candido_pred_proba_1_mdb")
        
      } else if (input$select_rel_emendas == "outros") {
        
        select_cols_emendas <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_outros", "lgbm_proba_1_outros", 
                              "cb_proba_1_outros", "candido_pred_proba_1_outros")
        
      } 
      
      
      datatable(preds_emendas[, select_cols_emendas],  extensions = 'Buttons', rownames = FALSE, 
                options = list(buttons = c('csv', 'excel'), scrollX = T, dom = 'lBfrtip', 
                               columnDefs = list(list(className = 'dt-center', targets = "_all"))))
  
  })
  
  
  ### beneficios
  
  output$select_rel_benef <- renderUI({
    
    selectInput("select_rel_benef", "Selecione o tema do modelo:",
                c("Geral" = "Geral",
                  "Bolsa Família" = "bolsa_familia",
                  "Benefício de Prestação Continuada" = "bpc",
                  "Seguro Defeso" = "seguro_defeso",
                  "Garafia-Safra" = "garantia_safra",
                  "Programa de Erradicação do Trabalho Infantil" = "peti"
                ))
    
  })
  

  
  output$vbox_rel_benef_xgb <- renderbs4ValueBox({
    
    if (input$select_rel_benef == "Geral" | input$select_rel_benef == "bolsa_familia" | input$select_rel_benef == "bpc") {
    
      bs4ValueBox(
        value = tags$b(p(dollar_format(prefix = "R$")(preds_beneficios[preds_beneficios$codigo_ibge==select_mun_beneficios()$codigo_ibge, 
                                                   c(ifelse(input$select_rel_benef == "Geral", "xgb_pred_geral_valor_per_capta", 
                                                            ifelse(input$select_rel_benef == "bolsa_familia", "xgb_pred_resid_bolsa_familia_valor_per_capta",
                                                                   "xgb_pred_resid_bpc_valor_per_capta")))]), style = "font-size: 210%;")),
        subtitle = paste("XGBoost - Decisão |", select_mun_beneficios()$nome_composto),
        color = "gray",
        width = 12,
        href = "https://xgboost.readthedocs.io/en/stable/"
      )
      
      
    } else {
      
      bs4ValueBox(
        value = tags$b(p(paste(round(preds_beneficios[preds_beneficios$codigo_ibge==select_mun_beneficios()$codigo_ibge, 
                                                   c(ifelse(input$select_rel_benef == "seguro_defeso", "xgb_proba_1_resid_seguro_defeso_binario", 
                                                            ifelse(input$select_rel_benef == "garantia_safra", "xgb_proba_1_resid_garantia_safra_binario",
                                                                   "xgb_proba_1_resid_peti_binario")))] * 100, 2), "%"), 
                         style = "font-size: 210%;")),
        subtitle = paste("XGBoost - Decisão |", select_mun_beneficios()$nome_composto),
        color = "gray",
        width = 12,
        href = "https://xgboost.readthedocs.io/en/stable/"
      )
      
    }
      
  })
  
  
  output$vbox_rel_benef_lgbm <- renderbs4ValueBox({
    
    if (input$select_rel_benef == "Geral" | input$select_rel_benef == "bolsa_familia" | input$select_rel_benef == "bpc") {
      
      bs4ValueBox(
        value = tags$b(p(dollar_format(prefix = "R$")(preds_beneficios[preds_beneficios$codigo_ibge==select_mun_beneficios()$codigo_ibge, 
                                                                       c(ifelse(input$select_rel_benef == "Geral", "xgb_pred_geral_valor_per_capta", 
                                                                                ifelse(input$select_rel_benef == "bolsa_familia", "xgb_pred_resid_bolsa_familia_valor_per_capta",
                                                                                       "xgb_pred_resid_bpc_valor_per_capta")))]), style = "font-size: 210%;")),
        subtitle = paste("LightGBM - Decisão |", select_mun_beneficios()$nome_composto),
        color = "gray",
        width = 12,
        href = "https://lightgbm.readthedocs.io/en/v3.3.2/"
      )
      
      
    } else {
      
      bs4ValueBox(
        value = tags$b(p(paste(round(preds_beneficios[preds_beneficios$codigo_ibge==select_mun_beneficios()$codigo_ibge, 
                                                      c(ifelse(input$select_rel_benef == "seguro_defeso", "lgbm_proba_1_resid_seguro_defeso_binario", 
                                                               ifelse(input$select_rel_benef == "garantia_safra", "lgbm_proba_1_resid_garantia_safra_binario",
                                                                      "lgbm_proba_1_resid_peti_binario")))] * 100, 2), "%"), 
                         style = "font-size: 210%;")),
        subtitle = paste("LightGBM - Decisão |", select_mun_beneficios()$nome_composto),
        color = "gray",
        width = 12,
        href = "https://lightgbm.readthedocs.io/en/v3.3.2/"
      )
      
    }

  })
  
  output$vbox_rel_benef_cb <- renderbs4ValueBox({
    
    if (input$select_rel_benef == "Geral" | input$select_rel_benef == "bolsa_familia" | input$select_rel_benef == "bpc") {
      
      bs4ValueBox(
        value = tags$b(p(dollar_format(prefix = "R$")(preds_beneficios[preds_beneficios$codigo_ibge==select_mun_beneficios()$codigo_ibge, 
                                                                       c(ifelse(input$select_rel_benef == "Geral", "cb_pred_geral_valor_per_capta", 
                                                                                ifelse(input$select_rel_benef == "bolsa_familia", "cb_pred_resid_bolsa_familia_valor_per_capta",
                                                                                       "cb_pred_resid_bpc_valor_per_capta")))]), style = "font-size: 210%;")),
        subtitle = paste("CatBoost - Decisão |", select_mun_beneficios()$nome_composto),
        color = "gray",
        width = 12,
        href = "https://catboost.ai/"
      )
      
      
    } else {
      
      bs4ValueBox(
        value = tags$b(p(paste(round(preds_beneficios[preds_beneficios$codigo_ibge==select_mun_beneficios()$codigo_ibge, 
                                                      c(ifelse(input$select_rel_benef == "seguro_defeso", "cb_proba_1_resid_seguro_defeso_binario", 
                                                               ifelse(input$select_rel_benef == "garantia_safra", "cb_proba_1_resid_garantia_safra_binario",
                                                                      "cb_proba_1_resid_peti_binario")))] * 100, 2), "%"), 
                         style = "font-size: 210%;")),
        subtitle = paste("CatBoost - Decisão |", select_mun_beneficios()$nome_composto),
        color = "gray",
        width = 12,
        href = "https://catboost.ai/"
      )
      
    }
    
  })
  
  output$vbox_rel_benef_candido <- renderbs4ValueBox({
    
    preds_beneficios$candido_pred_resid_bpc_valor_per_capta
    
    if (input$select_rel_benef == "Geral" | input$select_rel_benef == "bolsa_familia" | input$select_rel_benef == "bpc") {
      
      bs4ValueBox(
        value = tags$b(p(dollar_format(prefix = "R$")(preds_beneficios[preds_beneficios$codigo_ibge==select_mun_beneficios()$codigo_ibge, 
                                                                       c(ifelse(input$select_rel_benef == "Geral", "candido_pred_geral_valor_per_capta", 
                                                                                ifelse(input$select_rel_benef == "bolsa_familia", "candido_pred_resid_bolsa_familia_valor_per_capta",
                                                                                       "candido_pred_resid_bpc_valor_per_capta")))]), style = "font-size: 210%;")),
        subtitle = paste("Cândido - Decisão |", select_mun_beneficios()$nome_composto),
        color = "gray",
        width = 12,
        href = "https://en.wikipedia.org/wiki/Ensemble_learning"
      )
      
      
    } else {
      
      bs4ValueBox(
        value = tags$b(p(paste(round(preds_beneficios[preds_beneficios$codigo_ibge==select_mun_beneficios()$codigo_ibge, 
                                                      c(ifelse(input$select_rel_benef == "seguro_defeso", "candido_proba_1_resid_seguro_defeso_binario", 
                                                               ifelse(input$select_rel_benef == "garantia_safra", "candido_proba_1_resid_garantia_safra_binario",
                                                                      "candido_proba_1_resid_peti_binario")))] * 100, 2), "%"), 
                         style = "font-size: 210%;")),
        subtitle = paste("Cândido - Decisão |", select_mun_beneficios()$nome_composto),
        color = "gray",
        width = 12,
        href = "https://en.wikipedia.org/wiki/Ensemble_learning"
      )
    }
  })
  
  
  output$plot_rel_benefs_1 <- renderPlot({
    
    if (input$select_rel_benef == "Geral" | input$select_rel_benef == "bolsa_familia" | input$select_rel_benef == "bpc") {
    
      area <- ifelse(input$select_rel_benef == "Geral", "Geral", 
                     ifelse(input$select_rel_benef == "bpc", "Residual - BPC - Valor Per Capta", 
                            "Residual - Bolsa Família - Valor Per Capta"))
      
      
    data <- data.frame(
      Algoritmo = performance_mdl_reg[performance_mdl_reg$Tema=="Benefícios" & performance_mdl_reg$Área == area, c("Algoritmo")],  
      Valor = performance_mdl_reg[performance_mdl_reg$Tema=="Benefícios" & performance_mdl_reg$Área == area, c("R2")]
    )
    
    data$Algoritmo <- factor(data$Algoritmo,                                   
                             levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
    
    p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
      geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
      geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                position=position_stack(vjust=0.85)) + 
      theme(legend.position = "none") + 
      labs(title="R2", x ="Valor", y = "")
    
    p 
    
    } else {
      
      
      area <- ifelse(input$select_rel_benef == "seguro_defeso", "Residual - Seguro Defeso - Binário", 
                     ifelse(input$select_rel_benef == "garantia_safra", "Residual - Garantia-Safra - Binário", 
                            "Residual - PETI - Binário"))
      
      data <- data.frame(
        Algoritmo = performance_mdl[performance_mdl$Tema=="Benefícios" & performance_mdl$Área == area, c("Algoritmo")],  
        Valor = performance_mdl[performance_mdl$Tema=="Benefícios" & performance_mdl$Área == area, c("Accuracy")]
      )
      
      data$Algoritmo <- factor(data$Algoritmo,                                   
                               levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
      
      p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
        geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
        geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                  position=position_stack(vjust=0.85)) + 
        theme(legend.position = "none") + 
        labs(title="Accuracy", x ="Valor", y = "")
      
      p 
      
      
    }
    
  })

  
  output$plot_rel_benefs_2 <- renderPlot({
    
    if (input$select_rel_benef == "Geral" | input$select_rel_benef == "bolsa_familia" | input$select_rel_benef == "bpc") {
      
      area <- ifelse(input$select_rel_benef == "Geral", "Geral", 
                     ifelse(input$select_rel_benef == "bpc", "Residual - BPC - Valor Per Capta", 
                            "Residual - Bolsa Família - Valor Per Capta"))
      
      
      data <- data.frame(
        Algoritmo = performance_mdl_reg[performance_mdl_reg$Tema=="Benefícios" & performance_mdl_reg$Área == area, c("Algoritmo")],  
        Valor = performance_mdl_reg[performance_mdl_reg$Tema=="Benefícios" & performance_mdl_reg$Área == area, c("MSE")]
      )
      
      data$Algoritmo <- factor(data$Algoritmo,                                   
                               levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
      
      p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
        geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
        geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                  position=position_stack(vjust=0.85)) + 
        theme(legend.position = "none") + 
        labs(title="MSE", x ="Valor", y = "")
      
      p 
      
    } else {
      
      
      area <- ifelse(input$select_rel_benef == "seguro_defeso", "Residual - Seguro Defeso - Binário", 
                     ifelse(input$select_rel_benef == "garantia_safra", "Residual - Garantia-Safra - Binário", 
                            "Residual - PETI - Binário"))
      
      data <- data.frame(
        Algoritmo = performance_mdl[performance_mdl$Tema=="Benefícios" & performance_mdl$Área == area, c("Algoritmo")],  
        Valor = performance_mdl[performance_mdl$Tema=="Benefícios" & performance_mdl$Área == area, c("ROC_AUC")]
      )
      
      data$Algoritmo <- factor(data$Algoritmo,                                   
                               levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
      
      p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
        geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
        geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                  position=position_stack(vjust=0.85)) + 
        theme(legend.position = "none") + 
        labs(title="ROC-AUC", x ="Valor", y = "")
      
      p 
      
      
    }
    
  })
  
  
  output$plot_rel_benefs_3 <- renderPlot({
    
    if (input$select_rel_benef == "Geral" | input$select_rel_benef == "bolsa_familia" | input$select_rel_benef == "bpc") {
      
      area <- ifelse(input$select_rel_benef == "Geral", "Geral", 
                     ifelse(input$select_rel_benef == "bpc", "Residual - BPC - Valor Per Capta", 
                            "Residual - Bolsa Família - Valor Per Capta"))
      
      
      data <- data.frame(
        Algoritmo = performance_mdl_reg[performance_mdl_reg$Tema=="Benefícios" & performance_mdl_reg$Área == area, c("Algoritmo")],  
        Valor = performance_mdl_reg[performance_mdl_reg$Tema=="Benefícios" & performance_mdl_reg$Área == area, c("RMSE")]
      )
      
      data$Algoritmo <- factor(data$Algoritmo,                                   
                               levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
      
      p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
        geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
        geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                  position=position_stack(vjust=0.85)) + 
        theme(legend.position = "none") + 
        labs(title="RMSE", x ="Valor", y = "")
      
      p 
      
    } else {
      
      
      area <- ifelse(input$select_rel_benef == "seguro_defeso", "Residual - Seguro Defeso - Binário", 
                     ifelse(input$select_rel_benef == "garantia_safra", "Residual - Garantia-Safra - Binário", 
                            "Residual - PETI - Binário"))
      
      data <- data.frame(
        Algoritmo = performance_mdl[performance_mdl$Tema=="Benefícios" & performance_mdl$Área == area, c("Algoritmo")],  
        Valor = performance_mdl[performance_mdl$Tema=="Benefícios" & performance_mdl$Área == area, c("Log_Loss")]
      )
      
      data$Algoritmo <- factor(data$Algoritmo,                                   
                               levels = c("Ensemble", "CatBoost", "LGBM", "XGBoost"))
      
      p <- ggplot(data, aes(x = Valor, y = Algoritmo)) + 
        geom_bar(stat="identity", width=0.4, fill = ifelse(data$Algoritmo == "Ensemble", "#6c9a5f", "#616161")) + 
        geom_text(aes(label = round(Valor, 4)), colour = "white", size = 6,
                  position=position_stack(vjust=0.85)) + 
        theme(legend.position = "none") + 
        labs(title="Log_Loss", x ="Valor", y = "")
      
      p 
      
      
    }
    
  })
  
  
  output$table_rel_benef <- DT::renderDataTable(server = FALSE,{
    
    if (input$select_rel_benef == "Geral") {
      select_cols_benef <- c("codigo_ibge", "siafi_id", "nome", "xgb_pred_geral_valor_per_capta", "lgbm_pred_geral_valor_per_capta", 
                               "cb_pred_geral_valor_per_capta", "candido_pred_geral_valor_per_capta")
    } else if (input$select_rel_benef == "bolsa_familia") {
      
      select_cols_benef <- c("codigo_ibge", "siafi_id", "nome", "xgb_pred_resid_bolsa_familia_valor_per_capta", 
                               "lgbm_pred_resid_bolsa_familia_valor_per_capta", "cb_pred_resid_bolsa_familia_valor_per_capta", 
                              "candido_pred_resid_bolsa_familia_valor_per_capta")
    } else if (input$select_rel_benef == "bpc") {
      select_cols_benef <- c("codigo_ibge", "siafi_id", "nome", "xgb_pred_resid_bpc_valor_per_capta", "lgbm_pred_resid_bpc_valor_per_capta",
                               "cb_pred_resid_bpc_valor_per_capta", "candido_pred_resid_bpc_valor_per_capta")
    } else if (input$select_rel_benef == "seguro_defeso"){
      select_cols_benef <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_resid_seguro_defeso_binario", "lgbm_proba_1_resid_seguro_defeso_binario",
                               "cb_proba_1_resid_seguro_defeso_binario", "candido_pred_proba_1_resid_seguro_defeso_binario")
    } else if (input$select_rel_benef == "garantia_safra"){
      select_cols_benef <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_resid_garantia_safra_binario", "lgbm_proba_1_resid_garantia_safra_binario",
                               "cb_proba_1_resid_garantia_safra_binario", "candido_pred_proba_1_resid_garantia_safra_binario")
    }  else if (input$select_rel_benef == "peti"){
      select_cols_benef <- c("codigo_ibge", "siafi_id", "nome", "xgb_proba_1_resid_peti_binario", "lgbm_proba_1_resid_peti_binario",
                               "cb_proba_1_resid_peti_binario", "candido_pred_proba_1_resid_peti_binario")
    } 
    
    
    
    datatable(preds_beneficios[, select_cols_benef],  extensions = 'Buttons', rownames = FALSE, 
              options = list(buttons = c('csv', 'excel'), scrollX = T, dom = 'lBfrtip', 
                             columnDefs = list(list(className = 'dt-center', targets = "_all"))))
    
  })
  
  
  ### similaridades
  
  output$infobox_rel_sims1 <- renderbs4InfoBox({
    
    bs4InfoBox(title = paste0(select_mun_transf()$nome_composto, " | ", "Mun. Semelhante - 1º colocado"), 
               p(agg_municipios[agg_municipios$codigo_ibge==similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge,]$cod_mun_sim_rank1,]$nome_composto, style = "font-size: 120%;"), 
               color = "olive", icon = icon("1"),
               subtitle = paste0("Cod. IBGE: ", agg_municipios[agg_municipios$codigo_ibge==similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge,]$cod_mun_sim_rank1,]$codigo_ibge, 
                                 " | ", 
                                 "SIAFI ID: ", agg_municipios[agg_municipios$codigo_ibge==similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge,]$cod_mun_sim_rank1,]$siafi_id))
    
  })
  
  output$infobox_rel_sims2 <- renderbs4InfoBox({
    
    bs4InfoBox(title = paste0(select_mun_transf()$nome_composto, " | ", "Mun. Semelhante - 2º colocado"), 
               p(agg_municipios[agg_municipios$codigo_ibge==similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge,]$cod_mun_sim_rank2,]$nome_composto, style = "font-size: 120%;"),
               color = "warning", icon = icon("2"),
               subtitle = paste0("Cod. IBGE: ", agg_municipios[agg_municipios$codigo_ibge==similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge,]$cod_mun_sim_rank2,]$codigo_ibge, 
                                 " | ", 
                                 "SIAFI ID: ", agg_municipios[agg_municipios$codigo_ibge==similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge,]$cod_mun_sim_rank2,]$siafi_id))
    
  })
  
  output$infobox_rel_sims3 <- renderbs4InfoBox({
    
    bs4InfoBox(title = paste0(select_mun_transf()$nome_composto, " | ", "Mun. Semelhante - 3º colocado"),
               p(agg_municipios[agg_municipios$codigo_ibge==similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge,]$cod_mun_sim_rank3,]$nome_composto, style = "font-size: 120%;"),
               color = "lightblue", icon = icon("3"),
               subtitle = paste0("Cod. IBGE: ", agg_municipios[agg_municipios$codigo_ibge==similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge,]$cod_mun_sim_rank3,]$codigo_ibge, 
                                 " | ", 
                                 "SIAFI ID: ", agg_municipios[agg_municipios$codigo_ibge==similaridades[similaridades$codigo_ibge==select_mun_transf()$codigo_ibge,]$cod_mun_sim_rank3,]$siafi_id))
    
  })
  
  
  output$table_rel_sims = DT::renderDataTable({
    
    datatable(similaridades, extensions = 'Buttons', rownames = FALSE, 
              options = list(buttons = c('csv', 'excel'), scrollX = T, dom = 'lBfrtip', 
                             columnDefs = list(list(className = 'dt-center', targets = "_all"))))
    
  })
  
  
  
  ### SOBRE O PROJETO
  
  output$sobre_projeto <- renderUI({
    
    fluidRow(column(1), column(11,
                               fluidRow(column(1), column(10,tags$img(width = "75%", 
                                                                      src = "https://github.com/pbizil/geotesouro/blob/main/imgs/2.png?raw=true")),
                                        column(1)),
                               br(),
                               br(),
                               fluidRow(column(10, 
                                               tags$div(tags$p(tags$b("GeoTesouro é um protótipo de uma aplicação para identificação geoespacial das despesas da União."), 
                                                               "Com esse trabalho, o objetivo é identificar, nos 5570 municípios brasileiros, quais despesas chegam naquela localidade.", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p("Para identificar, de maneira inicial a localização das despesas, optou-se pelos seguintes temas:"), style = "font-size:20px;text-align: justify;"),
                                               tags$div(tags$p(" - ", tags$b("Transferências Governamentais da União aos Municípios"), ", identificada pelo campo 'Linguagem Cidadã' do Portal da Transparência;"), style = "font-size:20px;text-align: justify;"),
                                               tags$div(tags$p(" - ", tags$b("Benefícios ao Cidadão"), ", ou seja, programas de transferência direta de renda aos cidadãos brasileiros: Bolsa Família, BPC, PETI, Seguro Defeso e Garantia-Safra."), style = "font-size:20px;text-align: justify;"),
                                               tags$div(tags$p(" - ", tags$b("Convênios"), ", celebrados da União com os municípios;"), style = "font-size:20px;text-align: justify;"),
                                               tags$div(tags$p(" - ", tags$b("Emendas Parlamentares"), ", direcionadas exclusivamente aos municípios e plenamente identificada nos dados abertos;"), style = "font-size:20px;text-align: justify;"),
                                               tags$div(tags$p("Em geral, são temas relevantes no ponto de vista de transparência pública e podem ser aprimorados em termos de identificação geoespacial do dispêndio.", style = "font-size:20px;text-align: justify;"))),
                                        column(2)),
                               fluidRow(column(7),
                                        column(4, tags$img(width = "70%", 
                                                           src = "https://github.com/pbizil/geotesouro/blob/main/imgs/oxy.png?raw=true")), 
                                        column(1)),
                               br(),
                               tags$hr(),
                               fluidRow(column(10, tags$div(tags$p("Para incrementar a análise geolocalizada das despesas públicas do GeoTesouro, ao invés de dependermos 
                                      de análises propriamente de tendências do passado ou de apenas estatísticas descritivas, optou-se por desenvolver 
                                      um modelo de machine learning chamado Cândido, cujos resultados expressam probabilidades de terem alguma despesa 
                                      naquela localidade ou o valor per capta transferido.", style = "font-size:20px;text-align: justify;"))),
                                        column(2)),
                               br(),
                               fluidRow(column(10,tags$img(width = "40%", 
                                                           src = "https://github.com/pbizil/geotesouro/blob/main/imgs/logo_candido.png?raw=true")),
                                        column(1)),
                               br(),
                               fluidRow(column(10,tags$div(tags$p(tags$b("Cândido é um ensemble, ou seja, um conjunto de modelos de machine learning que decidem sobre os valores per capta que são destinados aos municípios ou 
                                     a probabilidade daquele município ter aquela despesa."), "Conforme explicitou a didatica.tech, estes metódos são:", style = "font-size:20px;text-align: justify;"))),
                                        column(2)),
                               fluidRow(column(10, bs4Quote("Estes métodos constroem vários modelos de machine learning, utilizando o resultado de cada modelo na definição de um único resultado, 
                  obtendo-se assim um valor final único. A resposta agregada de todos esses modelos é que será dada como o resultado final para cada dado que se está testando.", 
                                                            color = "gray")),
                                        column(2)),
                               fluidRow(column(10,tags$div(tags$p("A arquitetura do Cândido, portanto, envolveu não apenas um modelo único de estimação, mas a agregação de alguns importantes algoritmos de gradient boosting para aprimorar a estimação.", style = "font-size:20px;text-align: justify;"))),
                                        column(2)),
                               br(),
                               tags$h3(tags$b("Arquitetura - Cândido")),
                               br(),
                               fluidRow(column(10, tags$p("No Cândido, utilizou-se os três melhores modelos para performance de dados tabulares no mercado:", tags$a(href="https://xgboost.readthedocs.io/en/stable/", "XGBoost"), ", ", tags$a(href="https://lightgbm.readthedocs.io/en/v3.3.2/", "LightGBM"), " e ", tags$a(href="https://catboost.ai/","CatBoost"), ". Com eles, estabeleceu-se um 'comitê' - ou melhor: ensemble - no qual se decide 
  sobre o problema através de uma outra camada também com um modelo mais simples de machine learning: Regrressão Linear, para problemas de regressão, e Regressão Logística, para problemas de probabilidade ou binários. Ambos os modelos 
                             da segunda camada foram utilizados com configurações default da biblioteca Scikit-Learn.", style = "font-size:20px;text-align: justify;"),
                                               tags$p("Além da técnica de agregação de modelos, valeu-se de uma ferramenta para aprimorar a otimização dos hiperparâmetros dos três modelos da primeira camada: a ",  tags$a(href="https://microsoft.github.io/FLAML/", "FLAML"), ", uma biblioteca open source da Microsoft Research. 
                         O objetivo com essa ferramenta é buscar a otimização com baixo custo e tempo reduzido, além de já fornecer os caminhos para armazenamento dos modelos para utilização no ensemble do Cândido.", style = "font-size:20px;text-align: justify;")), column(2)),
                               br(),
                               fluidRow(column(1),
                                        column(10,
                                               tags$img(width = "70%", 
                                                        src = "https://github.com/pbizil/geotesouro/blob/main/imgs/candido_arquitetura.png?raw=true")),
                                        column(1)),
                               br(),
                               tags$h3(tags$b("Estrutura de Estimação - Cândido")),
                               br(),
                               fluidRow(column(10, tags$div(tags$p("A estrutura de estimação tem como base estimar os valores dos temas deste trabalho através 
  apenas de valores de informações geográficas (latitude, longitude, Estado e etc.), informações econômicas e demográficas. 
                                      Com esses dados, o modelo estima dois tipos de valores: ", tags$b("os principais e os residuais."), style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p("Os resultados principais consistem em: ", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p(" - ", "Para Transferências, são os valores per capta do total de transferências a determinado município;", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p(" - ", "Para Benefícios ao Cidadão, são o total de valores per capta de todos os benefícios destinados aos cidadãos daquele município;", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p(" - ", "Para Convênios, é a probabilidade de determinado município celebrar algum convênio;", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p(" - ", "Para Emendas, é a probabilidade de determinado município receber emendas parlamentares.", style = "font-size:20px;text-align: justify;"))), column(2)),
                               br(),
                               fluidRow(column(10, tags$div(tags$p("Os resultados residuais consistem em: ", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p(" - ", "Para Transferências, não há modelos residuais;", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p(" - ", "Para Benefícios ao Cidadão, são os valores per capta de Bolsa Família e BPC, e 
                                  as probabilidades do município ter algum cidadão que receba PETI, Seguro Defeso e Garantia-Safra;", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p(" - ", "Para Convênios, é a probabilidade de Ministérios celebrarem Convênio com o município;", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p(" - ", "Para Emendas, é a probabilidade de determinado partido destinar emendas parlamentares aos municípios.", style = "font-size:20px;text-align: justify;"))), column(2)),
                               br(),
                               fluidRow(column(1),
                                        column(9,
                                               tags$img(width = "70%", 
                                                        src = "https://github.com/pbizil/geotesouro/blob/main/imgs/candido_ensemble.png?raw=true")),
                                        column(2)),
                               br(),
                               tags$h3(tags$b("Similaridades entre os Municípios - Modelagem")),
                               br(),
                               fluidRow(column(10, tags$div(tags$p("Outro modelo, mais simplório, desenvolvido foi o de similaridade entre os municípios. 
                                     Com identificação entre municípios mais similares, é possível identificar localidades que possuem 
                                     características mais próximas aos do município selecionado e estabelecer comparações do resultado 
                                     do Cândido.", style = "font-size:20px;text-align: justify;")),
                                               tags$div(tags$p("A modelagem de similaridades buscou identificar a similiridades entre os municípios através do método de cosine similarity - 
                                  ou similaridade do coseno, da biblioteca Scikit-Learn. Com esse método, cada município, dada as suas características 
                                  geográficas, econômicas e demográficas, é transformado em vetor e depois se compara através do coseno em um determinado espaço. 
                                  Ao todo, construiu-se uma matriz de 5570 linhas, para cada município, com 10 colunas com a identificação dos municípios mais similares, 
                                  através do código IBGE.", style = "font-size:20px;text-align: justify;"))),
                                        column(2)),
                               br(),
                               fluidRow(column(10,
                                               bs4Card(tags$div(tags$p("Para desenvolver este projeto, optou-se por dividir os dados em dois grupos: ", tags$b("os principais e os secundários"), 
                                                                       ". Os principais foram responsáveis pelo desenvolvimento dos targets do modelo Cândido, 
                  enquanto os secundários são variáveis preditoras ou outros necessárias para execução do projeto."),
                                                                tags$p("Os dados foram coletados via webcrawlers ou manualmente, em suas respectivas fontes. São armazenados em SQLite."),
                                                                style = "font-size:20px;text-align: justify;"),
                                                       br(),
                                                       tags$h5(tags$b("Dados Principais")),
                                                       br(),
                                                       tags$div(tags$a(href="https://www.portaltransparencia.gov.br/download-de-dados/transferencias", tags$p(" - Transferências - CGU Portal da Transparência", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Dados de todas as Transferências, obrigatórias ou voluntárias, 
                                                        feitas pela União aos municípios;", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Fonte da variável alvo, Trasnferências Governamentais per capta, 
                                                        para o modelo Cândido.", style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://www.portaltransparencia.gov.br/download-de-dados/convenios", tags$p(" - Convênios - CGU Portal da Transparência", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Dados de Convênios celebrados pela União com os municípios, de 2010 a 2021;", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Fonte da variável alvo, proabilidade de celebrar um Convênio, para o modelo Cândido.", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://www.portaltransparencia.gov.br/download-de-dados/emendas-parlamentares", tags$p(" - Emendas Parlamentares - CGU Portal da Transparência", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Dados de Emendas Parlamentares identificadas por municípios;", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Fonte da variável alvo, proabilidade de receber uma Emenda, para o modelo Cândido.", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://www.portaltransparencia.gov.br/download-de-dados/bolsa-familia-pagamentos", tags$p(" - Benefícios ao Cidadão - Bolsa Família - CGU Portal da Transparência", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Dados de pagamentos de Bolsa Família por município, do período de 2013 a 2021;", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), " Fonte da variável alvo, valor total pago por município per capta, para o modelo Cândido.", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://www.portaltransparencia.gov.br/download-de-dados/bpc", tags$p(" - Benefícios ao Cidadão - Benefício de Prestação Continuada (BPC) - CGU Portal da Transparência", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Dados de pagamentos de BPC por município;", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Fonte da variável alvo, valor total pago por município per capta, para o modelo Cândido.", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://www.portaltransparencia.gov.br/download-de-dados/garantia-safra", tags$p(" - Benefícios ao Cidadão - Garantia-Safra - CGU Portal da Transparência", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Dados de pagamentos de Garantia-Safra por município;", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Fonte do modelo Cândido para estimação da probabilidade de haver pagamentos de Garantia-Safra em determinado município.", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://www.portaltransparencia.gov.br/download-de-dados/seguro-defeso", tags$p(" - Benefícios ao Cidadão - Seguro Defeso (Pescador Artesanal) - CGU Portal da Transparência", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Dados de pagamentos de Seguro Defeso por município;", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Fonte do modelo Cândido para estimação da probabilidade de haver pagamentos de Seguro-Defeso em determinado município.", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://www.portaltransparencia.gov.br/download-de-dados/peti", tags$p(" - Benefícios ao Cidadão - Erradicação do Trabalho Infantil (PETI) - CGU Portal da Transparência", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Dados de pagamentos do PETI por município;", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Fonte do modelo Cândido para estimação da probabilidade de haver pagamentos do PETI em determinado município.", 
                                                                                             style = "font-size:20px;text-align: justify;"))),
                                                       br(),
                                                       tags$h5(tags$b("Dados Secundários")),
                                                       br(),
                                                       tags$div(tags$a(href="https://github.com/kelvins/Municipios-Brasileiros", tags$p(" - Informações gerais dos municípios - Tabela RAW Github", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Dados de código IBGE, nome do município, capital, código UF, UF, estado, 
                                                        latitude, longitude, código SIAFI, DDD e fuso horário de todos (ou quase todos) os municípios brasileiros. Total de 5.570 registros;", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "código SIAFI e IBGE são instrumentos de agregação de tabelas. 
                                                        Outros dados são para variáveis preditoras do modelo Cândido.", style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://basedosdados.org/dataset/br-ibge-populacao?bdm_table=municipio", tags$p(" - População Municipal - BaseDosDados", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Fornece estimativas do total da população dos Municípios e das Unidades da Federação brasileiras, com data de referência em 1o de julho, para o ano calendário corrente. 
                                                        As estimativas populacionais foram coletadas desde 1991 até 2021;", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Entram como variáveis preditivas do modelo Cândido.", style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://basedosdados.org/dataset/br-ibge-pib?bdm_table=municipio", tags$p(" - Produto Interno Bruto Municipal - BaseDosDados", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Produto Interno Bruto (PIB) municipal a preços correntes. De 2002 a 2019;", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Entram como variáveis preditivas do modelo Cândido.", style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://github.com/ipeaGIT/geobr", tags$p(" - Dados Espaciais - GeoBR", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "GeoBR é um pacote R que permite que os usuários acessem facilmente os shapefiles do 
                                                        Instituto Brasileiro de Geografia e Estatística (IBGE) e outros conjuntos oficiais de dados espaciais do Brasil;", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Os dados coletados foram utilizados para criar as visualizações geoespaciais.", style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://dadosabertos.camara.leg.br/swagger/api.html", tags$p(" - Câmara dos Deputados - API Dados Abertos", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Requisição de nome e partido dos deputados federais, por legislatura;", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Coletou-se o nome e partido destes parlamentares para construir os modelos residuais de Emendas Parlamentares.", style = "font-size:20px;text-align: justify;"))),
                                                       tags$div(tags$a(href="https://www12.senado.leg.br/dados-abertos/conjuntos?portal=Legislativo&grupo=senadores", tags$p(" - Senado Federal - API Dados Abertos", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Sobre: "), "Requisição de nome e partido dos senadores, por legislatura;", style = "font-size:20px;text-align: justify;"))),
                                                       fluidRow(column(1), column(10, tags$p(" - ", tags$b("Função: "), "Coletou-se o nome e partido destes parlamentares para construir os modelos residuais de Emendas Parlamentares.", style = "font-size:20px;text-align: justify;"))),
                                                       width = 12, title = tags$b("Dados Utilizados no Projeto"),
                                                       closable = FALSE,
                                                       collapsed = FALSE,
                                                       collapsible = FALSE,
                                                       status = "gray")))
    ) 
    )
    
  })
  

}

shinyApp(ui, server)



