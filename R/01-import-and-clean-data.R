# Carregando funções personalizadas e dados das empresas
source("R/cad_cia.R")

# Definição dos tipos de balanço
bp <- c("BPA", "BPP")
ano <- 2023

comp_sample <- list()
for (i in 1:2) {
  dados <- read_dfp(ano, bp[i])
  comp_sample[[i]] <- create_comp_sample(dados)
}

comp_sample <- reduce(comp_sample, left_join, by = "Descrição")
colnames(comp_sample) <- c("Descrição","Ativo","Passivo")

# Processamento e geração de sumários
dados_lista <- map(bp, ~ {
  # Leitura e filtragem dos dados
  dados <- read_dfp(ano, .x) %>%
    filter(ORDEM_EXERC == "ÚLTIMO") %>%
    inner_join(semi_join(cad_cia, ., by = "CD_CVM"))


  # Segmentação dos dados em bancos e não bancos
  bancos <- dados %>% filter(SETOR_ATIV == "Bancos"| DENOM_CIA %in% c("BRAZILIAN FINANCE E REAL ESTATE S.A.",
                                                                      "SUL 116 PARTICIPACOES S.A.",
                                                                      "XP INVESTIMENTOS S.A."))
  dados_nao_bancos <- dados %>% filter(SETOR_ATIV != "Bancos") %>%
    filter(!DENOM_CIA %in% c("BRAZILIAN FINANCE E REAL ESTATE S.A.",
                             "SUL 116 PARTICIPACOES S.A.",
                             "XP INVESTIMENTOS S.A."))

  # Salvamento dos dados processados
  write.xlsx(dados_nao_bancos, glue("data/dfp_corrigido_{.x}_con_2023.xlsx"))
  write.xlsx(bancos, glue("data/dfp_bancos_{.x}_con_2023.xlsx"))

  # Criação e salvamento de sumários
  sumario <- create_summary(dados_nao_bancos, .x)

  # Retorno dos dados processados e sumário
  list(dados = dados_nao_bancos, bancos = bancos, sumario = sumario)
})

# Limpeza final opcional para objetos começando com "cad"
rm(list = ls(pattern = "^cad"))

sumario <- cbind(dados_lista[[1]][["sumario"]], dados_lista[[2]][["sumario"]][2])
sumario <- rename(sumario, "Ativo" = 2, "Passivo" = 3)
rm(dados_lista)
