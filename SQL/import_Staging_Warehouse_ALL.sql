whenever sqlerror exit
rollback;
begin
    INSERT INTO "WHOUSE"."produkt_WYMIAR" ("id_produktu", "cena", "marza_zawarta_w_cenie", "marka", "model",
                                           "producent", "kategoria", "rodzaj_produktu", "opis")
    SELECT "id_produktu",
           "cena",
           "marza_zawarta_w_cenie",
           "marka",
           "model",
           "producent",
           "kategoria",
           "rodzaj_produktu",
           "opis"
    FROM "STAGINGAREA"."produkt";
    COMMIT;

    INSERT INTO "WHOUSE"."lokalizacja_WYMIAR" ("id_lokalizacji", "miasto", "powiat", "wojewodztwo", "kraj",
                                               "odleglosc_od_centrum", "ilosc_klientow_w_zasiegu")
    SELECT "id_sklepu", "miasto", "powiat", "wojewodztwo", "kraj", "odleglosc_od_centrum", "ilosc_klientow_w_zasiegu"
    FROM "STAGINGAREA"."sklep";
    COMMIT;

    MERGE INTO "WHOUSE"."czas_WYMIAR" c
    USING (SELECT distinct round((EXTRACT(MINUTE FROM "czas") / 15)) kw,
                           EXTRACT(HOUR FROM "czas")                 go,
                           EXTRACT(DAY FROM "czas")                  dz,
                           EXTRACT(MONTH FROM "czas")                mi,
                           EXTRACT(YEAR FROM "czas")                 ro
           FROM "STAGINGAREA"."magazyn") w
    on (c."kwadrans" = w.kw and c."godzina" = w.go and c."dzien" = w.dz and c."miesiac" = w.mi and c."rok" = w.ro)
    WHEN NOT MATCHED THEN
        INSERT ("kwadrans", "godzina", "dzien", "miesiac", "rok")
        VALUES (w.kw, w.go, w.dz, w.mi, w.ro);
    COMMIT;

    MERGE INTO "WHOUSE"."czas_WYMIAR" c
    USING (SELECT distinct round((EXTRACT(MINUTE FROM "data_rozpoczecia") / 15)) kw,
                           EXTRACT(HOUR FROM "data_rozpoczecia")                 go,
                           EXTRACT(DAY FROM "data_rozpoczecia")                  dz,
                           EXTRACT(MONTH FROM "data_rozpoczecia")                mi,
                           EXTRACT(YEAR FROM "data_rozpoczecia")                 ro
           FROM "STAGINGAREA"."produkt_promocja") w
    on (c."kwadrans" = w.kw and c."godzina" = w.go and c."dzien" = w.dz and c."miesiac" = w.mi and c."rok" = w.ro)
    WHEN NOT MATCHED THEN
        INSERT ("kwadrans", "godzina", "dzien", "miesiac", "rok")
        VALUES (w.kw, w.go, w.dz, w.mi, w.ro);
    COMMIT;

    MERGE INTO "WHOUSE"."czas_WYMIAR" c
    USING (SELECT distinct round((EXTRACT(MINUTE FROM "data_zakonczenia") / 15)) kw,
                           EXTRACT(HOUR FROM "data_zakonczenia")                 go,
                           EXTRACT(DAY FROM "data_zakonczenia")                  dz,
                           EXTRACT(MONTH FROM "data_zakonczenia")                mi,
                           EXTRACT(YEAR FROM "data_zakonczenia")                 ro
           FROM "STAGINGAREA"."produkt_promocja") w
    on (c."kwadrans" = w.kw and c."godzina" = w.go and c."dzien" = w.dz and c."miesiac" = w.mi and c."rok" = w.ro)
    WHEN NOT MATCHED THEN
        INSERT ("kwadrans", "godzina", "dzien", "miesiac", "rok")
        VALUES (w.kw, w.go, w.dz, w.mi, w.ro);
    COMMIT;

    insert into WHOUSE."forma_ekspozycji_WYMIAR" ("id_formy_ekspozycji", "nazwa")
    SELECT "id_ekspozycji", "nazwa_formy_ekspozycji"
    from STAGINGAREA."ekspozycja";
    commit;

    MERGE INTO "WHOUSE"."sposob_platnosci_WYMIAR" s
    USING (SELECT distinct "transakcja"."rodzaj_platnosci"
           FROM "STAGINGAREA"."transakcja") t
    on (s."rodzaj" = t."rodzaj_platnosci")
    WHEN NOT MATCHED THEN
        INSERT ("rodzaj")
        VALUES (t."rodzaj_platnosci");
    COMMIT;

    MERGE INTO "WHOUSE"."promocja_WYMIAR" p
    USING (SELECT distinct pp."data_rozpoczecia",
                           pp."data_zakonczenia",
                           "promocja"."procentowa_wysokosc_rabatu",
                           cr."id_czasu" id_czasu_rozpoczecia,
                           cz."id_czasu" id_czasu_zakonczenia
           from STAGINGAREA."produkt_promocja" pp
                    natural join STAGINGAREA."promocja"
                    left join WHOUSE."czas_WYMIAR" cr
                              on (cr."kwadrans" = round((EXTRACT(MINUTE FROM pp."data_rozpoczecia") / 15)) and
                                  cr."godzina" = EXTRACT(HOUR FROM pp."data_rozpoczecia") and
                                  cr."dzien" = EXTRACT(DAY FROM pp."data_rozpoczecia") and
                                  cr."miesiac" = EXTRACT(MONTH FROM pp."data_rozpoczecia") and
                                  cr."rok" = EXTRACT(YEAR FROM pp."data_rozpoczecia"))
                    left join WHOUSE."czas_WYMIAR" cz
                              on (cz."kwadrans" = round((EXTRACT(MINUTE FROM pp."data_zakonczenia") / 15)) and
                                  cz."godzina" = EXTRACT(HOUR FROM pp."data_zakonczenia") and
                                  cz."dzien" = EXTRACT(DAY FROM pp."data_rozpoczecia") and
                                  cz."miesiac" = EXTRACT(MONTH FROM pp."data_rozpoczecia") and
                                  cz."rok" = EXTRACT(YEAR FROM pp."data_zakonczenia"))) pp
    on (p."id_czasu_rozpoczecia" = pp.id_czasu_rozpoczecia and p."id_czasu_zakonczenia" = pp.id_czasu_zakonczenia
        and p."procentowa_wysokosc_rabatu" = pp."procentowa_wysokosc_rabatu")
    WHEN NOT MATCHED THEN
        INSERT ("id_czasu_rozpoczecia", "id_czasu_zakonczenia", "procentowa_wysokosc_rabatu")
        VALUES (id_czasu_rozpoczecia, id_czasu_zakonczenia, pp."procentowa_wysokosc_rabatu");
    COMMIT;

    MERGE INTO "WHOUSE"."przedzial_cenowy_WYMIAR" pc
    USING (SELECT distinct (round(STAGINGAREA."produkt"."cena" / 10) * 10 - 5) od,
                           (round(STAGINGAREA."produkt"."cena" / 10) * 10 + 5) do
           from STAGINGAREA."produkt") pr
    on (pc."start_przedzialu_zawiera" = pr.od and pc."koniec_przedzialu" = pr.do)
    WHEN NOT MATCHED THEN
        INSERT ("start_przedzialu_zawiera", "koniec_przedzialu")
        VALUES (pr.od, pr.do);
    COMMIT;

    INSERT INTO WHOUSE."magazyn_FAKT"("id_produktu", "id_czasu", "id_lokalizacji", "suma_ilosci_produktow")
    SELECT "id_produktu",
           "id_czasu",
           "id_lokalizacji",
           "ilosc_sztuk"
    FROM "STAGINGAREA"."magazyn" st_ma
             left join WHOUSE."czas_WYMIAR" c
                       on (c."kwadrans" = round((EXTRACT(MINUTE FROM "czas") / 15)) and
                           c."godzina" = EXTRACT(HOUR FROM "czas") and c."dzien" = EXTRACT(DAY FROM "czas") and
                           c."miesiac" = EXTRACT(MONTH FROM "czas") and
                           c."rok" = EXTRACT(YEAR FROM "czas"))
             left join WHOUSE."lokalizacja_WYMIAR" l
                       on (l."id_lokalizacji" = st_ma."id_sklepu");

    INSERT INTO WHOUSE."zwroty_FAKT"("id_produktu", "id_czasu", "id_transakcji", "id_promocji",
                                     "id_przedzialu_cenowego_pojedynczego_produktu",
                                     "id_sposobu_platnosci", "suma_dochodow_utraconych", "suma_przychodow_utraconych",
                                     "suma_ilosci_zwroconych_produktow")
    SELECT st_zw."id_produktu",
           "id_czasu",
           "id_transakcji",
           1,
           "id_przedzialu_cenowego",
           1,
           p."marza_zawarta_w_cenie" * "ilosc_sztuk",
           p."cena" * "ilosc_sztuk",
           "ilosc_sztuk"
    FROM "STAGINGAREA"."zwrot" st_zw
             left join WHOUSE."czas_WYMIAR" c
                       on (c."kwadrans" = round((EXTRACT(MINUTE FROM "czas") / 15)) and
                           c."godzina" = EXTRACT(HOUR FROM "czas") and c."dzien" = EXTRACT(DAY FROM "czas") and
                           c."miesiac" = EXTRACT(MONTH FROM "czas") and
                           c."rok" = EXTRACT(YEAR FROM "czas"))
             left join WHOUSE."produkt_WYMIAR" p
                       on (p."id_produktu" = st_zw."id_produktu")
             left join WHOUSE."przedzial_cenowy_WYMIAR" pc
                       on (pc."start_przedzialu_zawiera" = (round("cena" / 10) * 10 - 5) and
                           pc."koniec_przedzialu" = (round("cena" / 10) * 10 + 5));
    COMMIT;

    INSERT INTO WHOUSE."sprzedaz_FAKT"("id_produktu", "id_czasu", "id_transakcji", "id_promocji", "id_lokalizacji",
                                       "id_formy_ekspozycji", "id_przedzialu_cenowego", "id_sposobu_platnosci",
                                       "suma_ilosci_zakupionych_produktow", "suma_dochodow",
                                       "suma_przychodow")
    SELECT st_sp."id_produktu",
           c."id_czasu",
           st_sp."id_transakcji",
           prw."id_promocji",
           "id_lokalizacji",
           "id_ekspozycji",
           "id_przedzialu_cenowego",
           "id_sposobu_platnosci",
           "ilosc_sztuk",
           "ilosc_sztuk" * "marza_zawarta_w_cenie",
           "ilosc_sztuk" * "cena"
    FROM "STAGINGAREA"."sprzedany_produkt" st_sp
             left join STAGINGAREA."transakcja" t
                       on (t."id_transakcji" = st_sp."id_transakcji")
             left join WHOUSE."lokalizacja_WYMIAR" l
                       on (l."id_lokalizacji" = t."id_sklepu")
             left join WHOUSE."czas_WYMIAR" c
                       on (c."kwadrans" = round((EXTRACT(MINUTE FROM t."czas") / 15)) and
                           c."godzina" = EXTRACT(HOUR FROM t."czas") and c."dzien" = EXTRACT(DAY FROM "czas") and
                           c."miesiac" = EXTRACT(MONTH FROM t."czas") and
                           c."rok" = EXTRACT(YEAR FROM t."czas"))
             left join WHOUSE."produkt_WYMIAR" p
                       on (p."id_produktu" = st_sp."id_produktu")
             left join WHOUSE."przedzial_cenowy_WYMIAR" pc
                       on (pc."start_przedzialu_zawiera" = (round("cena" / 10) * 10 - 5) and
                           pc."koniec_przedzialu" = (round("cena" / 10) * 10 + 5))
             left join WHOUSE."sposob_platnosci_WYMIAR" sp
                       on (sp."rodzaj" = t."rodzaj_platnosci")
             left join STAGINGAREA."produkt_promocja" pp
                       on (pp."id_produktu" = st_sp."id_produktu")
             left join STAGINGAREA."promocja" pr
                       on (pr."id_promocji" = pp."id_promocji")
             left join WHOUSE."czas_WYMIAR" cr
                       on (cr."kwadrans" = round((EXTRACT(MINUTE FROM pp."data_rozpoczecia") / 15)) and
                           cr."godzina" = EXTRACT(HOUR FROM pp."data_rozpoczecia") and
                           cr."dzien" = EXTRACT(DAY FROM pp."data_rozpoczecia") and
                           cr."miesiac" = EXTRACT(MONTH FROM pp."data_rozpoczecia") and
                           cr."rok" = EXTRACT(YEAR FROM pp."data_rozpoczecia"))
             left join WHOUSE."czas_WYMIAR" cz
                       on (cz."kwadrans" = round((EXTRACT(MINUTE FROM pp."data_zakonczenia") / 15)) and
                           cz."godzina" = EXTRACT(HOUR FROM pp."data_zakonczenia") and
                           cz."dzien" = EXTRACT(DAY FROM pp."data_rozpoczecia") and
                           cz."miesiac" = EXTRACT(MONTH FROM pp."data_rozpoczecia") and
                           cz."rok" = EXTRACT(YEAR FROM pp."data_zakonczenia"))
             left join WHOUSE."promocja_WYMIAR" prw
                       on (prw."id_czasu_rozpoczecia" = cr."id_czasu" and
                           prw."id_czasu_zakonczenia" = cz."id_czasu"
                           and prw."procentowa_wysokosc_rabatu" = pr."procentowa_wysokosc_rabatu")
             left join STAGINGAREA."produkt_ekspozycja" pe
                       on (pe."id_produktu" = st_sp."id_produktu");
    COMMIT;

end;
/

  