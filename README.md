# Hurtownia danych – Emisje gazów cieplarnianych

## Opis projektu
Projekt polegał na zaprojektowaniu i implementacji **hurtowni danych** dotyczącej emisji gazów cieplarnianych (CO₂, CH₄, N₂O).  
Model został przygotowany w oparciu o metodologię Ralpha Kimballa (model wymiarowo-faktowy).  
Celem było umożliwienie analizy emisji według krajów, źródeł emisji oraz czasu.
Dane pochodzą ze strony https://www.gapminder.org/. Dane zostały połączone i uporządkowane w SSIS. 
---

## Struktura repozytorium
- [`schema.sql`](schema.sql) – definicja bazy, schematów oraz tabel wymiarów i faktu  
- [`procedures.sql`](procedures.sql) – procedury ETL ładujące dane ze stagingu do wymiarów i faktu  
- [`load.sql`](load.sql) – skrypt wywołujący procedury w odpowiedniej kolejności (najpierw wymiary, potem fakt)  

---

## Architektura danych
- **Wymiary**:  
  - `DimEmissionType` – rodzaj emisji (CO₂, CH₄, N₂O)  
  - `DimEmissionSource` – źródła emisji  
  - `DimCountry` – kraje  
  - `DimCalendar` – czas (rok, stulecie, rok przestępny)  
- **Fakt**:  
  - `FactEmissions` – miary emisji, przechowywane z wykorzystaniem indeksu kolumnowego (Clustered Columnstore Index)  








