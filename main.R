#### Setup ####
needs <- function(...) {
  packages_list <- sapply(substitute(list(...))[-1], as.character)
  installed_packages <- lapply(packages_list, function(package_name) {
    short_name <- sub(".*?\\/", "", package_name)
    if (!short_name %in% installed.packages()[, "Package"]) {
      install.packages(package_name, repos = "https://cloud.r-project.org/")
    }
    suppressWarnings(suppressMessages(
      library(short_name, character.only = TRUE)
    ))
  })
  invisible()
}

needs(sf, tidyverse, glue, magrittr)

c(
  1949, 1953, 1957, 1961, 1965, 1969, 1972, 1976, 1980, 1983,
  1987, 1990, 1994, 1998, 2002, 2005, 2009, 2013, 2017, 2021
) -> election_years

read_sf("shapes_2025/wkr2025.shp") %>% st_transform(25832) -> geo_2025

c(
  "alternative_fuer_deutschland" = "afd",
  "b90gr" = "gruene",
  "buendnis90diegruenen" = "gruene",
  "buendnis_90die_gruenen" = "gruene",
  "bündnis 90/die grünen" = "gruene",
  "die grünen/bündnis 90" = "gruene",
  "grüne" = "gruene",
  "cdu" = "union",
  "christlich_demokratische_union_deutschlands" = "union",
  "christlichsoziale_union_in_bayern_ev" = "union",
  "csu" = "union",
  "csus" = "union",
  "die linke." = "linke",
  "die_linke" = "linke",
  "dielinke" = "linke",
  "pds" = "linke",
  "pds/ll" = "linke",
  "freie_demokratische_partei" = "fdp",
  "sozialdemokratische_partei_deutschlands" = "spd"
) -> party_replacements

get_boundaries_year_for_election_year <- function(election_year) {
  case_when(
    election_year %in% c(1949, 1953, 1957, 1961) ~ 1949,
    election_year %in% c(1965, 1969, 1972) ~ 1965,
    election_year %in% c(1980, 1983, 1987) ~ 1980,
    TRUE ~ election_year
  )
}

get_election_years_for_boundary_year <- function(boundary_year) {
  case_when(
    boundary_year == 1949 ~ "1949, 1953, 1957, 1961",
    boundary_year == 1965 ~ "1965, 1969, 1972",
    boundary_year == 1980 ~ "1980, 1983, 1987",
    TRUE ~ as.character(boundary_year)
  )
}

slugify <- function(str, add_pipe = TRUE) {
  if (add_pipe)
    c("ö" = "o|e", "ü" = "u|e", "ä" = "a|e", "ß" = "s|s", "(€|¶)" = "") -> umlaute_replacements
  else
    c("ö" = "oe", "ü" = "ue", "ä" = "ae", "ß" = "ss", "(€|¶)" = "") -> umlaute_replacements
  str %>%
    str_to_lower() %>%
    str_replace_all("\\|", "_") %>%
    str_replace_all(umlaute_replacements) %>%
    str_replace_all(" ", "_") %>%
    iconv(from = "UTF-8", to = "ASCII//TRANSLIT") %>%
    str_replace_all("[^0-9a-zA-Z\\|\\s_]", "") %>%
    str_replace_all("_+", "_")
}

#### Historische Ergebnisse einlesen ####
list.files(
  "data",
  "btw\\d{4}_kerg.csv",
  full.names = TRUE
) %>%
  map_dfr(\(current_path) {
    current_path %>% str_extract("\\d{4}") %>% as.integer() -> current_year
    "Lese Wahleregenbisse {current_year}" %>% glue() %>% print()
    case_when(
      current_year <= 1990 ~ "WINDOWS-1252",
      current_year >= 2017 ~ "utf-8",
      TRUE ~ "latin1"
    ) -> current_locale
    
    current_path %>%
      read_delim(
        ";",
        skip = case_when(
          current_year == 2021 ~ 2,
          TRUE ~ 5
        ),
        n_max = case_when(
          current_year >= 2005 ~ 3,
          TRUE ~ 2
        ),
        col_names = FALSE,
        locale = locale(encoding = current_locale),
        show_col_types = FALSE
      ) %>%
      data.table::transpose() %>%
      filter_all(any_vars(!is.na(.))) %>%
      mutate(V2 = if_else(current_year == 1949 & row_number() == 4, "zweitstimmen", V2)) %>%
      fill(1:2) %>%
      unite("colname", everything(), na.rm = TRUE) %>%
      mutate(
        colname = colname %>%
          str_replace_all("([A-Z])\\s", "\\1") %>%
          slugify(FALSE) %>%
          str_replace("_$", "") %>%
          str_replace("^_", "") %>%
          str_replace("^wahlkreis$", "wahlkreis_nr") %>%
          str_replace("^nr$", "wahlkreis_nr") %>%
          str_replace("^gebiet$", "wahlkreis_name") %>%
          str_replace("^waehler", "waehlende") %>%
          str_replace("gehoertzu", "gehoert_zu") %>%
          str_replace("(un)?gueltige_?stimmen", "\\1gueltige") %>%
          str_replace(".(erst|zweit)stimmen", "\\|\\1stimmen"),
        colname = if_else(row_number() == n() & str_detect(colname, "uebrige.zweit"), "drop", colname)
      ) %$% colname -> current_column_names

    current_path %>%
      read_delim(
        ";",
        skip = case_when(
          current_year == 2021 ~ 4,
          TRUE ~ 7
        ),
        col_names = current_column_names,
        locale = locale(encoding = current_locale),
        col_types = cols("c", "c", "c", .default = "i")
      ) %>%
      suppressWarnings() %>%
      select(1:length(current_column_names)) %>%
      mutate(jahr = current_year) %>%
      select(-matches("vorperiode"), -matches("^drop$")) %>%
      rename_with(~ str_replace(., "_endgueltig", ""), matches("_endgueltig")) %>%
      filter(!is.na(wahlkreis_nr)) %>%
      select(jahr, wahlkreis_nr, everything()) -> data
  }) %>%
  mutate(
    across(c(wahlkreis_nr, jahr), as.integer),
    across(c(wahlkreis_name), str_to_title),
    # ab 2017 haben die Bundesländer Nr. 1-16 statt 901-916 gekriegt
    wahlkreis_nr = if_else(
      jahr >= 2017 & (gehoert_zu == 99 | wahlkreis_name == "Bundesgebiet"),
      wahlkreis_nr + 900,
      wahlkreis_nr
    )
  ) %>%
  select(
    -land_name,
    -gehoert_zu
  ) %>%
  pivot_longer(
    c(
      -starts_with("jahr"),
      -starts_with("wahlkreis"),
      -starts_with("wahlberechtigte"),
      -starts_with("waehlende"),
      -starts_with("gueltige"),
      -starts_with("ungueltige")
    ),
    names_to = c("partei", "wahl"),
    names_sep = "\\|",
    values_to = "stimmen"
  ) %>%
  mutate(across(wahl, factor)) %>%
  rename_with(~ str_replace(., "\\|", "_")) %>%
  filter(!is.na(stimmen), stimmen > 0) %>%
  mutate(partei = str_replace_all(partei, party_replacements) %>% factor()) %>%
  # CDU und CSU sind 1957 im Saarland gegeneinander angetreten, aber wir addieren sie einfach
  group_by(across(c(-stimmen))) %>%
  summarize(across(stimmen, sum), .groups = "drop") %>%
  mutate(
    wahlberechtigte = coalesce(
      if_else(wahl == "erststimmen", wahlberechtigte_erststimmen, wahlberechtigte_zweitstimmen),
      wahlberechtigte_name,
      wahlberechtigte_erststimmen,
      wahlberechtigte_zweitstimmen
    ),
    waehlende = coalesce(
      if_else(wahl == "erststimmen", waehlende_erststimmen, waehlende_zweitstimmen),
      waehlende_name,
      waehlende_erststimmen,
      waehlende_zweitstimmen
    ),
    gueltige = if_else(wahl == "erststimmen", gueltige_erststimmen, gueltige_zweitstimmen),
    ungueltige = if_else(wahl == "erststimmen", ungueltige_erststimmen, ungueltige_zweitstimmen),
    anteil = round(stimmen / gueltige * 100, 2)
  ) %>%
  select(-matches("(wahlberechtigte|waehlende|gueltige|ungueltige)_(erststimmen|zweitstimmen|name)")) %>%
  arrange(jahr, wahlkreis_nr, partei, wahl) %>%
  mutate(across(wahlkreis_name, str_trim)) %>%
  filter(wahlkreis_nr < 900) -> historische_ergebnisse

#### Geocute ####
list.files(
  "geocute_results",
  "geocuted.*\\.tsv",
  full.names = TRUE
) %>%
  map_dfr(\(current_path) {
    basename(current_path) %>%
      str_extract("\\d{4}") %>%
      as.integer() -> current_year
    
    read_tsv(current_path, col_types = "iidddf") %>%
      mutate(jahr = current_year) %>%
      select(jahr, key_hist = 1, wahlkreis_nr = 2, fraction)
  }) %>%
  # fractions sind summiert nicht 1, deshalb "nochmal" normalisieren
  group_by(jahr, wahlkreis_nr) %>%
  mutate(fraction = fraction / sum(fraction)) %>%
  ungroup() %>%
  mutate(election_years = get_election_years_for_boundary_year(jahr)) %>%
  separate_rows(election_years, sep = ", ", convert = TRUE) %>%
  select(jahr = election_years, key_hist, wahlkreis_nr, fraction) %>%
  left_join(geo_2025 %>% st_drop_geometry() %>% select(wkr_id, bl), by = c("wahlkreis_nr" = "wkr_id")) %>%
  # Länder in jenen Jahren, in denen keine Wahlen stattfanden, entfernen
  # teilweise hatten die Daten weil sie so ganz leicht überschnitten
  filter(case_when(
    jahr >= 1990 ~ TRUE, # Osten ab 1990
    bl == "10" & jahr >= 1957 ~ TRUE, # Saarland ab 1957
    as.numeric(bl) < 10 ~ TRUE, # Westen (ohne Saarland) immer
    TRUE ~ FALSE
  )) %>%
  select(-bl) -> geocute_data

election_years %>%
  # wir machen das pro Jahr, weil es sonst zu breit/viele Spalten&Zeilen wird
  # mit allen Parteien aller Wahlzeiten in allen Wahlkreisen
  map_dfr(\(current_year) {
    "Verarbeite Geocute-Anteile für {current_year}" %>% glue() %>% print()
    historische_ergebnisse %>%
      filter(jahr == current_year) %>%
      rename(key_hist = wahlkreis_nr) %>%
      select(-anteil) %>%
      left_join(
        geocute_data %>% rename(wk_nr_2025 = wahlkreis_nr),
        by = c("jahr", "key_hist"),
        relationship = "many-to-many"
      ) %>%
      # weil nicht jede Partei in jedem Wahlkreis angetreten ist, müssen wir das sicherstellen
      pivot_wider(names_from = partei, values_from = stimmen, values_fill = 0) %>% 
      pivot_longer(
        cols = -c(jahr:fraction),
        names_to = "partei",
        values_to = "stimmen"
      ) %>%
      group_by(jahr, wahlkreis_nr = wk_nr_2025, partei, wahl) %>%
      summarize(
        across(c(stimmen, wahlberechtigte, waehlende, gueltige, ungueltige), ~ sum(. * fraction, na.rm = TRUE)),
        keys_hist = paste(key_hist, collapse = ", "),
        fractions = paste(round(fraction, 2), collapse = ", "),
        .groups = "drop"
      ) %>%
      filter(stimmen >= 1) -> current_results
  }) %>%
  mutate(anteil = stimmen / gueltige * 100) %>%
  left_join(
    geo_2025 %>%
      select(wahlkreis_nr = wkr_id, wahlkreis_name = name) %>%
      st_drop_geometry(),
    by = "wahlkreis_nr"
  ) %>%
  mutate(
    across(anteil, ~ round(., 2)),
    across(c(stimmen, wahlberechtigte, waehlende, gueltige, ungueltige), as.integer)
  ) %>%
  select(jahr, wahlkreis_nr, wahlkreis_name, partei, stimmen, anteil, everything()) %>%
  arrange(jahr, wahlkreis_nr, desc(wahl)) -> geocuted_results

glue(
  "In {n} Wahlkreisen beträgt die Summe aller Stimmenanteile über 100%",
  n = geocuted_results %>%
    group_by(jahr, wahlkreis_nr, wahlkreis_name, wahl) %>%
    summarize(across(
      c(stimmen, anteil, wahlberechtigte, waehlende, gueltige, ungueltige),
      sum
    ), .groups = "drop") %>%
    filter(anteil > 100.1) %>%
    nrow()
)

# Datensatz der Bundeswahlleiterin mit offiziell umgerechneten Werten 2021>2025
"data/btwkr25_umrechnung_btw21.csv" %>%
  read_delim(
    ";",
    skip = 4,
    n_max = 2,
    col_names = FALSE,
    show_col_types = FALSE
  ) %>%
  data.table::transpose() %>%
  filter_all(any_vars(!is.na(.))) %>%
  unite("colname", everything(), na.rm = TRUE) %>%
  mutate(
    colname = colname %>%
      str_replace_all("([A-Z])\\s", "\\1") %>%
      str_replace("\\s\\(.*?$", "") %>%
      slugify(FALSE) %>%
      str_replace("_$", "") %>%
      str_replace("^_", "") %>%
      str_replace("^wkrnr$", "wahlkreis_nr") %>%
      str_replace("^wahlkreisname$", "wahlkreis_name") %>%
      str_replace("gueltig\\_", "gueltige|") %>%
      str_replace(".(erst|zweit)stimmen", "\\|\\1stimmen")
  ) %$% colname -> column_names_2021

"data/btwkr25_umrechnung_btw21.csv" %>%
  read_delim(
    ";",
    skip = 6,
    col_names = column_names_2021,
    col_types = cols("i", "-", "c", .default = "i")
  ) %>%
  mutate(jahr = as.integer(2021)) %>%
  filter(wahlkreis_nr < 900) %>%
  select(
    -matches("wahlberechtigte_[a-z]+"),
    -matches("waehlende_[a-z]+"),
  ) %>%
  pivot_longer(
    c(
      -starts_with("jahr"),
      -starts_with("wahlkreis"),
      -starts_with("wahlberechtigte"),
      -starts_with("waehlende"),
      -starts_with("gueltige"),,
      -starts_with("ungueltige"),
    ),
    names_to = c("partei", "wahl"),
    names_sep = "\\|",
    values_to = "stimmen"
  ) %>%
  mutate(across(wahl, factor)) %>%
  rename_with(~ str_replace(., "\\|", "_")) %>%
  filter(!is.na(stimmen), stimmen > 0) %>%
  mutate(partei = str_replace_all(partei, party_replacements) %>% factor()) %>%
  mutate(
    gueltige = if_else(wahl == "erststimmen", gueltige_erststimmen, gueltige_zweitstimmen),
    ungueltige = if_else(wahl == "erststimmen", ungueltige_erststimmen, ungueltige_zweitstimmen),
    anteil = round(stimmen / gueltige * 100, 2)
  ) %>%
  select(-matches("(gueltige|ungueltige)_(erststimmen|zweitstimmen)")) -> offizielle_umrechnung_21_25

# Export
geocuted_results %>%
  filter(jahr != 2021) %>%
  bind_rows(offizielle_umrechnung_21_25) %>%
  mutate(across(partei, factor)) %>%
  filter(wahl == "zweitstimmen") %>%
  select(-wahl) %>%
  arrange(jahr, wahlkreis_nr, desc(stimmen)) %>%
  write_csv("historische_wahlkreisergebnisse.csv") %>%
  write_rds("historische_wahlkreisergebnisse.rds")
