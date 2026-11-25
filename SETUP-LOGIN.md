# Jhumka Base: sign-in setup (about 15 minutes, once)

What you get: every person signs in with email + password. You (the owner) add emails; only added emails can create an account. First time, Jhumka emails a 6-digit security code. Access lasts until you remove the email.

## 1. Create the Supabase project
1. Go to supabase.com, sign up (free), **New project**. Pick a region near India (Mumbai) and save the database password.
2. Open **SQL Editor > New query**, paste all of `supabase/setup.sql`, change the owner email on the line marked `<<< YOUR EMAIL` if needed, press **Run**.

## 2. Turn on the security code email
1. **Authentication > Providers > Email**: Enable email provider, keep **Confirm email ON**, minimum password length 8. Keep OTP length 6.
2. **Authentication > Emails > Templates**. In **Confirm signup**, **Reset Password** and **Magic Link**, replace the body with:

       <h2>Your Jhumka security code</h2>
       <p>Enter this code in Jhumka Base:</p>
       <h1 style="letter-spacing:6px">{{ .Token }}</h1>
       <p>It expires in one hour. If this was not you, ignore this email.</p>

   Set the subject to `Your Jhumka security code`. The body must contain `{{ .Token }}` (the code), not a link.
3. **Authentication > SMTP Settings**: enable custom SMTP so mail comes from "Jhumka" and is not rate-limited to 2 per hour. Use any provider (Brevo, Resend, Gmail app password...). Sender name: `Jhumka`, sender email: your brand email.
4. **Authentication > URL Configuration**: set Site URL to your website address (the GitHub Pages link).

## 3. Connect the website
1. **Project Settings > API**: copy the **Project URL** and the **anon public** key (the anon key is meant to be public).
2. Open `config.js` in this folder, paste them between the quotes, save, and upload to GitHub with the rest.

## 4. First use
1. Open the site, tap **First time here? Create account**, use your owner email, choose a password, enter the code from your email.
2. Profile > **People with access**: type an email, tap **Give access**. Tell that person to open the site and tap Create account.
3. To end someone's access: **Remove access** next to their email. They are signed out within a minute and cannot sign up again unless you add them again.

## Notes
- Existing data on one device does not move to the cloud automatically. Use Profile > Backup to export before switching, then import after signing in.
- Staff can add and change entries; settings, roles and monthly targets are owner-only, enforced by the database. Which tabs each role sees is still set in the app.
- Forgot password: **Forgot password** on the sign-in screen sends a new code.
- Leave `config.js` empty to run without sign-in (data stays on the device).
