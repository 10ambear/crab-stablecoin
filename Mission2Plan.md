# Mission 2 Meeting Plan

## Breakdown of Mission tasks
- [ ] Liquidity for your stablecoin so it can be swapped on a decentralized exchange in your local environment.


### [Task 2] - Notes
- The new governance setup broke our governance tests

## Meetings

### How many meetings do you think will be necessary?
- already met once, possibly meeting again

### What days/times will you choose to meet this week?
- not set in stone tbh

## Attack Plan

### [Sheep] Goals & Responsibilities

- [x] Positions that fall below the required LTV ratio for their basket of collateral and corresponding borrow amount can be “liquidated” (force-closed) with a liquidate function.
    - [ ] tests 
- [x] Governance proposals must have passed the 5 day voting period since proposal to be executable.
- [x] Governance proposals cannot be voted on outside of the 5 day voting period.
- [x] Only proposals with >50% of the totalSupply in voting power may be executed.
- [ ] When governance proposals are executed, the proposed ltv is configured in the CDP system for the defined collateralToken.

### [bLnk] Goals & Responsibilities
- [x] Governance tokens may be staked in a Staker contract.
- [x] Interest fees that are generated from the CDP protocol debt are distributed to stakers.