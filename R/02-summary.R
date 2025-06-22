dados_bp <- list()

for (i in seq_along(bp)) {

  dados <- read_dados(bp[i])

  # Remover duplicadas
  dados <- dados |> distinct()

  # Filtragem dos dados para resolver o problema com TENDA S.A.
  dados_ <- dados |> filter(ORDEM_EXERC == "ÚLTIMO",
                            DENOM_CIA != "CONSTRUTORA TENDA S.A.")

  tenda_sa  <- dados |> filter(ORDEM_EXERC == "ÚLTIMO",
                               DT_REFER == "2023-12-31",
                               DENOM_CIA == "CONSTRUTORA TENDA S.A.")

  # Combina os dados e armazena na lista
  dados_bp[[i]] <- bind_rows(dados_, tenda_sa)

  # Remover variáveis temporárias
  rm(dados_, tenda_sa)
}








