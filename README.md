# Collaborative Open-Source Textbook DAO

A DAO for open textbooks where contributors submit edits, the community votes with staked tokens, and accepted edits mint rewards to the proposer.

## Features 📚
- Stake-weighted voting on edit proposals
- Inline token with staking and transfers
- Configurable quorum to pass proposals
- Accepted edits update chapter state and mint rewards

## Contract
- Path: contracts/Collaborative-Open-Source-Textbook-DAO.clar

## Key Functions 🧩
- owner-mint(to, amt) -> owner mints governance tokens
- transfer(to, amt) -> transfer tokens
- stake(amt) / unstake(amt) -> lock/unlock tokens for voting
- set-min-quorum(q) -> owner sets minimal yes-weight
- propose(chapter, hash, reward, duration) -> open an edit proposal
- vote(id, support) -> cast a vote using staked weight
- finalize(id) -> finalize and mint reward if passed
- balance-of(who) / stake-of(who) -> read balances
- get-proposal(id) / proposal-tally(id) -> read proposal data
- get-chapter(id) -> current chapter hash and revision

## Quickstart ▶️
1) Open Clarinet console
```
clarinet console
```

2) Set contract identifier
```
(define-constant c .Collaborative-Open-Source-Textbook-DAO)
```

3) Bootstrap tokens and quorum 🏁
```
(contract-call? c owner-mint tx-sender u1000)
(contract-call? c set-min-quorum u100)
```

4) Stake and propose ✍️
```
(contract-call? c stake u500)
(contract-call? c propose u1 "QmHashOfChapter1Edit" u200 u0)
```

5) Vote and finalize 🗳️
```
(contract-call? c vote u0 true)
(contract-call? c finalize u0)
```

6) Read state 🔎
```
(read-only-call? c proposal-tally u0)
(read-only-call? c get-chapter u1)
```

## Line Endings 🧰
Ensure files use LF only. On Windows PowerShell, normalize like this:
```
(Get-Content "contracts/Collaborative-Open-Source-Textbook-DAO.clar" -Raw).Replace("`r`n", "`n") | Set-Content "contracts/Collaborative-Open-Source-Textbook-DAO.clar" -NoNewline
(Get-Content "README.md" -Raw).Replace("`r`n", "`n") | Set-Content "README.md" -NoNewline
```

## Compile ✅
```
clarinet check
```

# Collaborative Open-Source Textbook DAO

