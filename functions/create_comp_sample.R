create_comp_sample <- function(dados) {
  # Filtrar apenas registros com ordem de exercício = ÚLTIMO
  dados_ultimo <- dados |>
    semi_join(cad_cia, by = "CD_CVM") |>  # Mantém só as empresas do cad_cia
    inner_join(cad_cia, by = "CD_CVM") |>   # Adiciona variáveis de cad_cia
    filter(ORDEM_EXERC == "ÚLTIMO")

  comp_sample <- tibble(
    Descrição = c(
      "Empresas Distintas",
      "( - ) Ordens de exercício social = “ÚLTIMO”",
      "( - ) Observações Duplicadas",
      "( - ) Observações Triplicadas",
      "( - ) Construtora Tenda S.A.",
      "( - ) Setor de Atividade = “Bancos”",
      "( - ) Brazilian Finance e Real Estate S.A.",
      "( - ) Sul 116 Participações S.A.",
      "( - ) XP Investimentos S.A.",
      "( - ) BB Seguridade Participações S.A.",
      "( - ) IRB - Brasil Resseguros S.A."
    ),
    Valor = c(
      # 1. Empresas distintas no conjunto completo
      nrow(dados),

      # 2. Total de linhas em 'PENÚLTIMO'
      nrow(dados)-nrow(dados_ultimo),

      # 3. Nº de empresas que têm exatamente 2 observações idênticas
      nrow(dados_ultimo |>
             filter(duplicated(across(everything()))) |>
             distinct()),

      # 4. Nº de empresas que têm observações triplicadas (3+ linhas idênticas)
      nrow(
        dados_ultimo |>
          group_by(across(everything())) |>
          filter(n() >= 3) |>
          distinct(DENOM_CIA) |>
          ungroup()
      ),

      # 5. Ocorrências da Construtora Tenda em 31/03/2023
      nrow(
        dados_ultimo |>
          filter(
            DENOM_CIA == "CONSTRUTORA TENDA S.A.",
            DT_REFER == "2023-03-31"
          )
      ),

      # 6. Linhas do setor 'Bancos'
      nrow(dados_ultimo |> filter(SETOR_ATIV == "Bancos")),

      # 7. Ocorrências específicas de outras empresas
      nrow(dados_ultimo |> filter(DENOM_CIA == "BRAZILIAN FINANCE E REAL ESTATE S.A.")),
      nrow(dados_ultimo |> filter(DENOM_CIA == "SUL 116 PARTICIPACOES S.A.")),
      nrow(dados_ultimo |> filter(DENOM_CIA == "XP INVESTIMENTOS S.A.")),
      nrow(dados_ultimo |> filter(DENOM_CIA == "BB SEGURIDADE PARTICIPAÇÕES S.A.")),
      nrow(dados_ultimo |> filter(DENOM_CIA == "IRB - BRASIL RESSEGUROS S.A."))
      )
  )

  return(comp_sample)
}

