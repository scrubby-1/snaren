# Snaarmeter

Meet de spanning van tennissnaren via de toon van een tik. Leerlingen maken een account met jouw clubcode; jij ziet als trainer hun rackets en wie moet herbespannen.

## Bestanden

- `index.html` – de app
- `config.js` – hier vul je je Supabase-gegevens in
- `setup.sql` – maakt de database en beveiliging aan
- `manifest.webmanifest`, `icon-*.png`, `apple-touch-icon.png` – app-icoon op het beginscherm

## 1. Supabase (login en database)

1. Maak een gratis account op supabase.com en klik **New project**. Kies als regio **Central EU (Frankfurt)** en bewaar het databasewachtwoord ergens veilig.
2. Open **SQL Editor**, plak de volledige inhoud van `setup.sql` en klik **Run**.
3. Kies je clubcode. Voer in de SQL Editor uit (met je eigen code):
   `update public.instellingen set clubcode = 'JOUWCODE' where id = 1;`
4. Ga naar **Authentication > Sign In / Providers > Email** en zet **Confirm email** uit. Leerlingen kunnen dan meteen inloggen. (Laat je het aan, dan moeten ze eerst een bevestigingsmail openen; de gratis mailservice van Supabase verstuurt maar een beperkt aantal mails per uur.)
5. Ga naar **Project Settings > API** (of de knop **Connect**) en kopieer de **Project URL** en de **publishable key** (bij oudere projecten heet die "anon public").
6. Plak beide in `config.js`.

## 2. Vercel (de app online zetten)

1. Maak op github.com een nieuwe repository, bv. `snaarmeter`.
2. Kies "uploading an existing file" en sleep alle bestanden uit deze map erin. Klik **Commit changes**.
3. Ga naar vercel.com/new, log in met GitHub en importeer de repository. Laat alle instellingen staan en klik **Deploy**.
4. Zet in Supabase bij **Authentication > URL Configuration** de **Site URL** op je Vercel-link (nodig voor "Wachtwoord vergeten").

## 3. Jezelf trainer maken

1. Open je Vercel-link, kies **Account maken** en gebruik je clubcode.
2. Voer in de Supabase SQL Editor uit (met je eigen e-mailadres):
   `update public.profiles set rol = 'trainer' where id = (select id from auth.users where email = 'JOUW-EMAIL');`
3. Log uit en opnieuw in. Bovenaan verschijnt nu **Leerlingen**.

## 4. Leerlingen uitnodigen

Geef hen de link en de clubcode. Op de gsm kiezen ze **Zet op beginscherm** voor een eigen app-icoon.

## Goed om te weten

- Een gratis Supabase-project pauzeert na 7 dagen zonder gebruik. Je krijgt vooraf een mail en zet het terug aan met **Resume project**; de gegevens blijven bewaard.
- Leerlingen zien alleen hun eigen rackets. Alleen accounts met de rol trainer zien alles.
- Vergeet een leerling zijn wachtwoord: via "Wachtwoord vergeten?" krijgt hij een mail. Je kan een account ook verwijderen in **Authentication > Users**; zijn gegevens verdwijnen dan mee.
- Nieuwe versie van de app? Vervang `index.html` op GitHub; Vercel zet ze automatisch online. `config.js` blijft staan.
