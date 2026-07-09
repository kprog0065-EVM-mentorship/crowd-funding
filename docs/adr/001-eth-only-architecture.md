# ADR 001: ETH-only crowdfunding campaigns

## Status
Accepted

## Context
The assignment explicitly requires ETH contributions and ETH withdrawals/refunds.

## Decision
Implement crowdfunding campaigns as ETH-only. Each campaign is stored as an onchain record inside a single contract.

## Consequences
Simpler accounting, easier testing, and less implementation risk. ERC-20 support can be added later as a separate feature.