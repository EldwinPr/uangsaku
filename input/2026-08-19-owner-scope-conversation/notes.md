# Owner scope conversation — initial needs

- **Source:** Eldwin (owner, sole stakeholder, also the developer)
- **Date:** 2026-08-19
- **Channel:** working session (chat)
- **Contents:** this file only — no attachments. The material is the owner's own
  statements during the session, recorded verbatim below.

Note on provenance: the owner is also the developer here, so there is no
external client to check against. That makes this record *more* load-bearing
than usual, not less — there is nobody else who will remember what was actually
asked for versus what got designed in afterwards.

---

## Verbatim — raw statements

Quoted as written, typos and all. Do not clean these up; the wording is the
evidence.

**Opening ask:**

> i want to make an application for tracking my money on my mobile phone

**The six raw items** (given when asked for uncategorised needs):

> these are inputs or uncategorized needs from me, 1. accounts 2. transactions,
> 3. debts, 4. ballances, 5. budget, 6. people who owe me money. for transaction
> i might need collumns for category and budget group (ex: transporation can go
> for travel or work)

**Answers to three follow-up questions** — (1) is a credit card an account or a
debt, (2) do debt payments link to real transactions or just get ticked off,
(3) are category and budget group required or optional:

> 1. debt, 2. just tick but also show how much is paid, this is why ballance is
> important, it's not ballance ballance it's balance sheet something like that,
> 3. optional

**On the account model:**

> i was considering to take the accounting approach to handle credit and debit
> but that removes usability from the app. maybe we can actually make account
> into two types credit and debit, that way debt is actually transaction in
> credit account, making it really easy to sort and easy to check ballance

**Clarifying what "accounting approach" meant:**

> by accounting approach i meant making coa and actual balance sheet

**On budgets** (asked how budget should work):

> oh for budget set a soft limit similiar to account, say budget each month,
> this will turn into debit, each time it's used it becomes credit bit by bit.
> which then will be clear in balance sheet and if i want to implement somesort
> of monthly report, dashboard, or ai integration it's easier

> i meant budget is another table that acts like account, that's why we have
> account, budget, category/sub

> no rollover, unlike account which is continues, budget stops at that month to
> keep the report faithful

**On budget identity, repetition, and category depth** (asked whether the
allocation repeats, and whether categories are two levels):

> food is fine to be kept per month or per whatever, in the end it depends on
> how you query it. automatically but can change it, maybe lock it after first
> week. yes category + sub

**On the balance-sheet screen** (asked whether spendable money and money owed
to him should be one figure or two):

> separate spendable from owed to me

**On the remaining open items** (asked about unbudgeted spending, the budget
lock, editing/deleting, and backup):

> just put it under others, hard lock, yeah crud for everything, backup for
> later. is ocr possible?

**On whether editable transactions conflict with locked budgets:**

> not really a tension i think, budget stays, transaction editable. whether
> cleaning it or not depends on the person. so budget just helps

---

## What these statements establish

Reading, not quoting. Kept separate from the verbatim block above on purpose.

1. **"Balances" meant balance sheet, not account balances.** Corrected
   explicitly by the owner. This reframes the application: it is a net-worth
   tracker that records spending, not a spending tracker that shows balances.
2. **A credit card is a debt, not an account** — owner's answer to Q1.
3. **Debt repayment is "tick it off, but show how much is paid."** No
   requirement to link repayments to individual transactions as a user-visible
   feature.
4. **Category and budget group are two independent, optional axes** on a
   transaction. The owner's own example: transportation may belong to travel or
   to work. This is an explicit rejection of the common design where budget is
   simply a limit attached to a category.
5. **Accounts have two types (owner's words: credit and debit)**, and a debt is
   then just transactions against a credit-type account. Owner's stated
   motivation: sorting and balance-checking become easy.
6. **Usability outranks accounting correctness.** The owner considered and
   rejected a chart of accounts and a formal balance sheet specifically because
   they cost usability. This is a constraint, not a preference.

7. **Budget is a third table**, alongside accounts and categories — not an
   account, though it behaves like one in holding an amount that drains.
8. **Budgets are monthly and do not roll over**, deliberately, so that a
   month's report reflects only that month. Accounts run continuously; budgets
   do not.
9. **Budget allocation repeats automatically** month to month, and is editable.
10. **Categories are exactly two levels** — category and subcategory.
12. **Spendable money and money owed to the owner stay separate** on the
    balance-sheet screen. Accounts therefore group three ways, not two.
11. **Reporting is a stated future direction** — monthly report, dashboard, AI
    integration were given as the reason for the account-like budget shape.
    None are in scope; they constrain the shape of what is recorded.

## Open at the end of this session

- OCR of receipts — owner asked, was told it is feasible but forecloses a
  browser-only stack, and deferred it to the same standing as backup. Not a
  requirement.
- Naming: "credit/debit account" collides with debit/credit as entry directions
  and with credit cards. Raised in session, not resolved.
- Stack, platform, domain language, currency — all untouched.

## Extracted

- All six items + clarifications -> `docs/fr-nfr.md` (FR-1 … FR-16, NFR-1 …
  NFR-3), 2026-08-19
- Account-model decision -> `context/index/decisions.md`, 2026-08-19
