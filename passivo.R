# Pacotes -----------------------------------------------------------------
library(tidyverse)
library(openxlsx)
library(extrafont)
library(ggthemes)
library(xtable)
library(glue)
library(patchwork)
library(grid)
library(shadowtext)
library(stringi)
library(moments)
library(GetFREData)
library(oneinfl)
library(fastDummies)

# Limpando ----------------------------------------------------------------
rm(list=ls())

# list functions ----------------------------------------------------------
my_R_files <- list.files(path ="functions", pattern = '*.R',
                         full.names = TRUE)

# Load all functions in R  ------------------------------------------------
sapply(my_R_files, source)

# Lendo os arquivos ----------------------------------------------------
bp <- c("BPA","BPP")
ano <- 2023
comp_sample <- list()
df_list <- list()
conta_origem <- list()
source("R/cad_cia.R")

# Inicialize uma lista para armazenar os resultados
for (i in 1:2) {

    # Leia os dados
  dados <- read_dfp(ano, bp[i])
  comp_sample[[i]] <- create_comp_sample(dados)

  # Filtrar dados e resolver problemas específicos
  dados <- dados |>
    filter(ORDEM_EXERC == "ÚLTIMO") |> distinct()

  # Filtragem dos dados para resolver o problema com TENDA S.A.
  dados_ <- dados |> filter(DENOM_CIA != "CONSTRUTORA TENDA S.A.")
  tenda_sa  <- dados |> filter(DT_REFER == "2023-12-31",
                               DENOM_CIA == "CONSTRUTORA TENDA S.A.")

  # Combina os dados e armazena na lista
  dados <- bind_rows(dados_, tenda_sa)

  # Adicionar setores
  cad_cia <- semi_join(cad_cia, dados, by = c("CD_CVM"))
  dados <- inner_join(dados, cad_cia)

  # Criar base somente de bancos
  bancos <- dados |>
    filter(SETOR_ATIV == "Bancos" |
             DENOM_CIA %in% c("BRAZILIAN FINANCE E REAL ESTATE S.A.",
                              "SUL 116 PARTICIPACOES S.A.",
                              "XP INVESTIMENTOS S.A.",
                              "BB SEGURIDADE PARTICIPAÇÕES S.A.",
                              "IRB - BRASIL RESSEGUROS S.A."))

  # Remover bancos da base principal
  dados <- dados |>
    filter(SETOR_ATIV != "Bancos") |>
    filter(!DENOM_CIA %in% c("BRAZILIAN FINANCE E REAL ESTATE S.A.",
                             "SUL 116 PARTICIPACOES S.A.",
                             "XP INVESTIMENTOS S.A.",
                             "BB SEGURIDADE PARTICIPAÇÕES S.A.",
                             "IRB - BRASIL RESSEGUROS S.A."))
  conta_origem[[i]] <- dados |>
    filter(nchar(CD_CONTA) == 7) |>
    select(CD_CONTA, DS_CONTA) |>
    count(CD_CONTA,DS_CONTA,name="frequencia") |>
    select(-3)

  # Quantidade de contas diferentes
  contas <- dados |>
    distinct(CD_CONTA) |>
    pull()

  # Criar data frame por conta
  df_bpa <- map_dfr(contas, ~ {
    dados %>%
      filter(CD_CONTA == .x) %>%
      count(DS_CONTA) %>%
      mutate(Cod = .x)
  })

  # Processar resultados
  x <- df_bpa |>
    group_by(Cod) |>
    summarise(empresas = sum(n))
  y <- df_bpa |>
    count(Cod)
  df <- left_join(x, y)

  # Adicionar nível e filtrar
  df_list[[i]] <- df |>
    mutate(nivel = case_when(
      nchar(Cod) == 1 ~ "1",
      nchar(Cod) == 4 ~ "2",
      nchar(Cod) == 7 ~ "3",
      nchar(Cod) == 10 ~ "Quatro",
      nchar(Cod) == 13 ~ "Cinco",
    )) |>
    relocate(nivel, .before = empresas) |>
    rename("terminologias" = n) |>
    filter(nivel %in% c("Quatro", "Cinco"))
}

# Após o loop, combine os resultados em um único data frame, se necessário
base <- bind_rows(df_list)
comp_sample <- reduce(comp_sample, left_join, by = "Descrição")
colnames(comp_sample) <- c("Descrição","Ativo","Passivo")
rm(list = setdiff(ls(),c("base","conta_origem","comp_sample")))
conta_origem <- rbind(conta_origem[[1]],conta_origem[[2]])
colnames(conta_origem) <- c("cod_origem","origem")
df <- base |>
  mutate(cod_origem = substr(Cod, 1, 7)) |>
  left_join(conta_origem, by = "cod_origem")|>
  mutate(df = factor(case_when(
    substr(Cod, 1, 1) == "1" ~ "ativo",
    substr(Cod, 1, 1) == "2" ~ "passivo"
  ))
  )
sumario_1 <- df |>
  group_by(cod_origem, origem, df) |>
  reframe(
    Freq = n(),
    "Prop Quarto Nível" = sum(nivel == "Quatro") / n(),
    "Prop Quinto Nível" = sum(nivel == "Cinco") / n(),
    Média = mean(terminologias, na.rm = TRUE),
    "Desvio Padrão" = sd(terminologias, na.rm = TRUE),
    Mínimo = min(terminologias, na.rm = TRUE),
    Máximo = max(terminologias, na.rm = TRUE),
    "Primeiro quartil" = quantile(terminologias, probs = 0.25, na.rm = TRUE),
    Mediana = median(terminologias, na.rm = TRUE),
    "Terceiro quartil" = quantile(terminologias, probs = 0.75, na.rm = TRUE)
  )
sumario_2 <- df |>
  group_by(nivel, df) |>
  reframe(
    Freq = n(),
    Média = mean(terminologias, na.rm = TRUE),
    "Desvio Padrão" = sd(terminologias, na.rm = TRUE),
    Mínimo = min(terminologias, na.rm = TRUE),
    Máximo = max(terminologias, na.rm = TRUE),
    "Primeiro quartil" = quantile(terminologias, probs = 0.25, na.rm = TRUE),
    Mediana = median(terminologias, na.rm = TRUE),
    "Terceiro quartil" = quantile(terminologias, probs = 0.75, na.rm = TRUE)
  )
sumario_3 <- df |>
  group_by(df) |>
  reframe(
    Freq = n(),
    "Prop Quarto Nível" = sum(nivel == "Quatro") / n(),
    "Prop Quinto Nível" = sum(nivel == "Cinco") / n(),
    Média = mean(terminologias, na.rm = TRUE),
    "Desvio Padrão" = sd(terminologias, na.rm = TRUE),
    Mínimo = min(terminologias, na.rm = TRUE),
    Máximo = max(terminologias, na.rm = TRUE),
    "Primeiro quartil" = quantile(terminologias, probs = 0.25, na.rm = TRUE),
    Mediana = median(terminologias, na.rm = TRUE),
    "Terceiro quartil" = quantile(terminologias, probs = 0.75, na.rm = TRUE)
  )

mediana <- sumario_1 |>
  select(1,Mediana, Média) |>
  mutate(AT = ifelse(str_sub(cod_origem,1,1)=="1","Sim","Não")) |>
  filter(AT == "Não") |>
  select(-AT) |>
  mutate(PL = ifelse(str_sub(cod_origem,3,4)=="03","Sim","Não")) |>
  filter(PL == "Não") |>
  select(-PL)

df <- df |>
  mutate(prop = terminologias/empresas, .before = terminologias)

df_passivo <- df |>
  filter(df=="passivo") |>
  mutate(circ=ifelse(str_sub(Cod,3,4)=="01","pc","npc"),.before = nivel) |>
  mutate(origem=paste(origem,circ," ")) |>
  select(-circ) |>
  mutate(PL = ifelse(str_sub(Cod,3,4)=="03","Sim","Não")) |>
  filter(PL == "Não") |>
  select(-PL) |>
  left_join(mediana) |>
  mutate(dist_med = terminologias - Mediana)



# Clusterização ----
set.seed(5)
cluster <- df_passivo |>
  select(3:5,9:11)
cluster_padronizado <- as.data.frame(scale(cluster[,]))
cluster_kmeans <- kmeans(cluster_padronizado,
                         centers = 4)
df_passivo$cluster_K <- factor(cluster_kmeans$cluster)
df_passivo |>
  ggplot()+
  aes(x = empresas, y = terminologias,
      color = cluster_K)+
  geom_point(size=5) +
  scale_x_continuous(breaks=seq(0,180,30)) +
  ggthemes::scale_color_hc() +
  labs(y = "Qtde de terminologias utilizadas",
       x = "Qtde de empresas")

df_passivo <- dummy_cols(df_passivo, select_columns = "origem",
                         remove_first_dummy = FALSE,
                         remove_selected_columns = FALSE)

colnames(df_passivo) <- c("Cod", "nível", "num_emp", "prop", "comp_term", "cod_origem",
                          "origem", "natureza", "mediana", "media", "dist_med",
                          "cluster_K",
                          "emp_fin_pnc",
                          "emp_fin_pc", "fornec", "luc_rec_aprop", "obr_fisc", "obr_soc_trab",
                          "outras_obr_pnc", "outras_obr_pc",
                          "panc_vend_pnc", "panc_vend_pc", "prov_pnc", "prov_pc",
                           "trib_def")

df_passivo <- dummy_cols(df_passivo, select_columns = "cluster_K",
                         remove_first_dummy = FALSE,
                         remove_selected_columns = FALSE)

df_passivo <- df_passivo |>
  mutate(nível=ifelse(nível=="Quatro",FALSE,TRUE))

formula_OIZTNB <- comp_term ~  -1 + log(num_emp) + fornec +
  emp_fin_pc + cluster_K_1 + outras_obr_pnc + outras_obr_pc  +
  mediana| cluster_K_3 + cluster_K_2

OIZTNB <- oneinfl(formula_OIZTNB,
                  df_passivo, dist="negbin")

summary(OIZTNB)

OIPP <- oneinfl(formula_OIZTNB,
                  df_passivo, dist="Poisson")

summary(OIPP)


formula_ZTNB <- comp_term ~  -1 + log(num_emp) + fornec +
  emp_fin_pc + cluster_K_3 + outras_obr_pnc + outras_obr_pc  +
  prov_pc

ZTNB <- truncreg(formula_ZTNB,
                 df_passivo, dist="negbin")

summary(ZTNB)
