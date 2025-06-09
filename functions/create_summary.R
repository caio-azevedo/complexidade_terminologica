# Definindo a função de criação de sumário
create_summary <- function(dados, tipo) {
  sumario <- tibble(
    Descrição = c("Nº de empresas", "Nº de emp. com informações duplicadas",
                  "Nº de emp. com informações triplicadas",
                  "Nº de contas diferentes", "Nº de terminologias diferentes",
                  "Média de terminologias por conta"),
    Valor = c(
      n_distinct(dados$DENOM_CIA),
      n_distinct(dados %>% filter(duplicated(.)) %>% distinct(DENOM_CIA)),
      n_distinct(dados %>% filter(duplicated(.)) %>% filter(duplicated(.)) %>% distinct(DENOM_CIA)),
      n_distinct(dados$CD_CONTA),
      n_distinct(dados %>% select(DS_CONTA, CD_CONTA) %>% distinct(DS_CONTA)),
      round(n_distinct(dados %>% select(DS_CONTA, CD_CONTA) %>% distinct(DS_CONTA)) / n_distinct(dados$CD_CONTA), 2)
    )
  )
  return(sumario)
}
