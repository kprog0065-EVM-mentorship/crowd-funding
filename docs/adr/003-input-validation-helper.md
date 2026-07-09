# ADR 003: Centralized input validation for campaign creation

## Status
Accepted

## Context
The crowdfunding contract allows users to create campaigns with user-supplied inputs including title, description, funding goal, and duration. These inputs must be validated before storing them onchain to prevent invalid campaign records and to enforce basic security and business rules.

## Decision
Campaign creation inputs will be validated before a campaign is stored. The validation logic will live in a dedicated internal helper function instead of being duplicated inline across the contract.

## Reasons
- Input validation is required to reject empty titles, empty descriptions, zero funding goals, and invalid durations.
- Centralizing validation keeps the main create function easier to read.
- A helper function makes the validation reusable if additional functions later need similar checks.
- This approach reduces the risk of forgetting a validation rule in one place while applying it in another.

## Consequences
- The contract is easier to maintain and audit.
- Validation behavior is consistent across the codebase.
- The helper adds a small amount of abstraction, but the improved readability is worth it.
- Future campaign-related functions can reuse the same validation rules.