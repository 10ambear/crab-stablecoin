# TODO - MISSION 1

## StableCoin
- [ ] Users can deposit 3 different types of collateral
	- [ ] weth
	- [ ] usdc
	- [ ] solana

- [ ] Users can withdraw their deposited collateral from their position with the `withdrawCollateral` function.

- [ ] Users can borrow your stablecoin against their multi-collateral position up to the LTV allowed by their aggregate collateral with the `borrow` function.

- [ ] Users can repay their debt in your stablecoin with the `repay` function.

- [ ] Interest is charged on user’s debt that must be repaid in the protocol stablecoin.

- [ ]  LTV ratios are initially set on deployment, but can be adjusted through a governance process:
    - [ ] Holders of the governance token with more than 1% of the supply can create a proposal for the LTV ratios with a `propose` function.
    - [ ] In the `propose` function, the proposer automatically votes for the proposal with all of their balance.
    - [ ] Holders of the governance token can vote with their balance on a proposal with the `vote` function.
    - [ ] The proposal execution function and proposal passing logic is left for Mission 2 and is _not_ included in Mission 1.

## Governance

- [ ] Proposing
- [ ] Voting


# official readme

### How does the system work? How would a user interact with it?

### What actors are involved? Is there a keeper? What is the admin tasked with?

### What are the known risks/issues?

### Any pertinent formulas used.

### What is the paradox described? What is your decision to address it and why?


