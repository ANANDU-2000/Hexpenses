# MoneyFlow AI — guide for new users

This short guide helps you **get started** with the MoneyFlow AI app: what you see on each screen, how to add money movements, and where to find budgets, documents, and settings.

If you are a **developer** setting up the project, see **[HOW_TO_RUN.md](HOW_TO_RUN.md)** instead.

---

## 1. First time you open the app

1. **Create an account or sign in** using the email and password your administrator or invite gave you.  
2. If you are trying the **offline demo build** (no server), you may skip login and see a **Get started** walkthrough the first time you open the app. You can open it again from **Profile → Demo → Get started**.  
3. If you are trying a **demo with a live server**, your team may have shared a **demo email and password** (often created when the database is seeded).  
4. After login (or in demo mode), you land on **Home**, with a bottom bar to move between main areas.

**Tip:** Amounts are shown in **Indian format** with an **INR / rupee** prefix where the app is configured for India.

---

## 2. Bottom navigation (main tabs)

| Tab | What it is for |
|-----|----------------|
| **Home** | Overview: balance, income / expense summary, quick actions, and recent activity. |
| **Transactions** | List of your expenses and money-out (and related activity). Use the **+** button or list actions to add or manage entries. |
| **Analytics** | Charts and summaries to see patterns in your spending and income over time. |
| **Profile** | Your account, preferences, sign out, and links to deeper settings. |

**Centre (+) button:** Opens a **quick create** sheet so you can add common items (for example a new expense) without hunting through menus.

---

## 3. Home screen

- **Greeting and profile:** Your name (or email) and a shortcut to profile.  
- **Balance card:** Shows an **available balance** view when your accounts are connected in the app.  
- **Summary chips:** Typical labels include **Income**, **Expense**, and **Cashflow** so you see the direction of money at a glance.  
- **Quick actions** (icons such as Send, Receive, Add, More):  
  - **Send / Receive:** Flows for transfers or UPI-style actions (depending on what your build enables).  
  - **Add income:** Opens the flow to record money coming in.  
  - **More:** Opens extra shortcuts (accounts, budgets, documents, reports, etc.).  
- **Recent activity:** Latest transactions; you can often open an item for details or pull the list down to **refresh** data when you are online.

**Pull down to refresh:** On many lists, dragging down **syncs** the latest data from the server when the app is connected to the backend.

---

## 4. Adding income and expenses

- **Income:** Use **Add income** from Home quick actions, or paths your app shows under **More** / **Income**. Enter amount, date, category or source, and notes if needed.  
- **Expenses:** From **Transactions**, use **add** or the **+** (FAB). Choose category, amount, and date.  
- **Categories:** Pick the category that best matches the spend (food, transport, bills, etc.) so **Analytics** and **Budgets** stay accurate.

---

## 5. Budgets

Open **Budgets** from **More** on Home (or the route your build uses). There you can:

- Set **monthly limits** per category (or as your app displays them).  
- See **spent vs limit** so you know if you are close to or over budget.

---

## 6. Accounts, investments, and other areas

From **More** on Home you can usually reach:

- **Accounts** — bank balances and cards grouped in one place.  
- **Investments** — portfolio-style holdings, if enabled.  
- **Insurance** / **Vehicles** / **Documents** — store policies, assets, and files.  
- **Reports** — broader monthly or yearly views.  
- **Notifications** — alerts from the app.  
- **Insights** — tips or AI-style summaries based on your data.

Exact labels may vary slightly by app version; if something is missing, your team may have turned that module off.

---

## 7. Analytics tab

Use **Analytics** to:

- Compare **income vs expense** over weeks or months.  
- Spot **categories** where you spend the most.  
- Support decisions like adjusting budgets or cutting discretionary spend.

---

## 8. Profile and settings

Under **Profile** you can typically:

- See or edit **your name and email** (if the server allows).  
- Switch **light / dark theme** when available.  
- **Sign out** securely on shared devices.

---

## 9. Offline use and sync

- Some builds can work **offline** with data stored on your device; when you are back online, the app may **sync** with the server automatically or when you **pull to refresh**.  
- If numbers look stale, connect to the internet and refresh, or ask your administrator whether your environment uses **live API** or **demo-only** mode.

---

## 10. Need help?

- **Wrong balance or missing transaction:** Check you are logged into the correct account, then refresh; if it persists, contact support.  
- **Cannot log in:** Reset password if your server supports it, or ask your admin to verify your account.  
- **Developers:** Database demo user and admin panel login are documented in **[HOW_TO_RUN.md](HOW_TO_RUN.md)**.

---

*MoneyFlow AI — HEXASTACK SOLUTION \| Surag*
