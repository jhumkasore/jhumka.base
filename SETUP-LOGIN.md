# Jhumka Base: sign-in setup (about 15 minutes, once)

What you get: every person signs in with email + password. You (the owner) add emails; only added emails can create an account. First time, Jhumka sends a verification email: tap the link in it (or type the 6-digit code, if you switch the email to codes). Access lasts until you remove the email.

## 1. Create the Supabase project
1. Go to supabase.com, sign up (free), **New project**. Pick a region near India (Mumbai) and save the database password.
2. Open **SQL Editor > New query**, paste all of `supabase/setup.sql`, change the owner email on the line marked `<<< YOUR EMAIL` if needed, press **Run**.

## 2. Turn on the verification email
1. **Authentication > Providers > Email**: Enable email provider, keep **Confirm email ON**, minimum password length 8.
2. **Authentication > URL Configuration** (needed, or the email link opens the wrong address):
   - **Site URL**: `https://jhumkasore.github.io/jhumka.base/`
   - **Redirect URLs > Add URL**: `https://jhumkasore.github.io/jhumka.base/`
3. **Authentication > SMTP Settings**: set up custom SMTP so mail comes from "Jhumka" and goes to any address. Without it Supabase only sends a few emails an hour, and only to members of your Supabase team. Use any provider (Brevo, Resend, Gmail app password...). Sender name: `Jhumka`, sender email: your brand email.

No template changes are needed. Supabase's standard emails contain a **link**; tapping it opens Jhumka Base already verified (or on the New password screen for a reset).

Optional, codes instead of links: once custom SMTP is on, the **Authentication > Emails > Templates** editor unlocks. In **Confirm signup** and **Reset Password**, replace the body with:

       <h2>Your Jhumka security code</h2>
       <p>Enter this code in Jhumka Base:</p>
       <h1 style="letter-spacing:6px">{{ .Token }}</h1>
       <p>It expires in one hour. If this was not you, ignore this email.</p>

   and keep the code length at 6 under **Providers > Email**. The app accepts both, so either way works.

## 3. Connect the website
1. **Project Settings > API**: copy the **Project URL** and the **anon public** key (the anon key is meant to be public).
2. Open `config.js` in this folder, paste them between the quotes, save, and upload to GitHub with the rest.

## 4. First use
1. Open the site, tap **Create account**, enter your name, your owner email and a password, tap **Create account**, then open the email from Jhumka and tap the link (or type the code).
2. Profile > **People with access**: type an email, tap **Give access**. Tell that person to open the site and tap Create account.
3. To end someone's access: **Remove access** next to their email. They are signed out within a minute and cannot sign up again unless you add them again.

## The sign-in screen
It uses the app's own look (same colours, fonts and light/dark switch), and works on phones and desktop.
- **Sign in / Create account** switch at the top of the card.
- **Create account** shows 3 steps: Your details, Verify email, Ready. The name entered here fills in the person's profile.
- **Check your inbox**: tap the link in the email. If the link opens in another tab on the same device, the first tab carries on by itself when you come back to it. If the email has a 6-digit code instead, type it in the six boxes (paste and phone autofill work). "Send the email again" unlocks after 60 seconds.
- Used or expired links show "That email link has expired or was already used" on the sign-in screen.
- If someone created an account but never verified, signing in sends a fresh verification email.
- Only emails the owner added can create an account, and removed people are signed out within a minute.

## Notes
- Existing data on one device does not move to the cloud automatically. Use Profile > Backup to export before switching, then import after signing in.
- Staff can add and change entries; settings, roles and monthly targets are owner-only, enforced by the database. Which tabs each role sees is still set in the app.
- Forgot password: **Forgot password** on the sign-in screen emails a reset link; it opens the New password screen.
- Leave `config.js` empty to run without sign-in (data stays on the device).
