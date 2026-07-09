# ADR 003: Single-contract architecture for crowdfunding campaigns

## Status
Accepted

## Context
The crowdfunding platform must support multiple campaigns, contributions, withdrawals, refunds, and status tracking. A design decision was required on whether to use one contract that stores all campaigns internally or a factory pattern that deploys a separate contract for each campaign.

## Decision
The platform will use a single smart contract to manage all crowdfunding campaigns. Each campaign will be represented as a struct stored in contract state and identified by a unique campaign ID.

## Reasons
- The assignment requirements can be fully satisfied with one contract.
- A single-contract design is simpler to implement, test, and deploy.
- Campaigns can be tracked efficiently using mappings and incremental IDs.
- This design avoids the extra complexity of deploying and managing a new contract for every campaign.
- Frontend integration is simpler because the application only needs to interact with one contract address.
- Refund, withdrawal, and contribution logic can be centralized in one place.

## Consequences
- All campaign state is stored in one contract, so the contract is responsible for maintaining correct accounting for each campaign.
- The contract must carefully separate campaign balances using internal mappings and campaign IDs.
- The design is easier to understand for a capstone project, but it is less modular than a factory-plus-per-campaign-contract architecture.
- Future versions could migrate to a factory architecture if campaign isolation or extensibility becomes more important.

## Alternatives Considered

### Factory + per-campaign contracts
Deploying a separate contract for each campaign would provide stronger isolation between campaigns and more modular deployment patterns. However, it adds deployment overhead, increases architectural complexity, and makes the frontend and testing setup more involved.

### Hybrid architecture
A hybrid model with one registry contract and external campaign contracts was considered, but it was rejected because it adds complexity beyond what is necessary for the current project scope.

## Notes
This decision is intended for version 1 of the crowdfunding platform and prioritizes simplicity, maintainability, and clarity over maximum modularity.