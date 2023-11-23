# CrabStableCoin
The system is a decentralized stablecoin system called Crab. It is designed to maintain a 1 token == $1 peg at all times. The system allows users to deposit collateral, borrow stablecoins, and repay borrowed stablecoins. The system is based on the MakerDAO DSS system.

Users interact with the system through the following functions:

- depositCollateral: Users can deposit collateral into their position. Only supported collateral tokens are allowed.
- withdrawCollateral: Users can withdraw collateral from their position.
- borrow: Users can borrow protocol stablecoins against their collateral.
- repay: Users can repay protocol stablecoins from their debt.

## What actors are involved? Is there a keeper? What is the admin tasked with?
There are two main actors involved in the system:

Users: They interact with the system by depositing collateral, borrowing stablecoins, and repaying borrowed stablecoins.
Owner: The Owner is responsible for setting up the system, adding coins and feeds, and managing the protocol.

## What are the known risks/issues?
The system has a few known risks and issues:

The system relies on external price feeds for collateral tokens. If these price feeds are manipulated or inaccurate, it could lead to a loss of funds for users.
The system has a limit on the number of times a user can borrow. If a user exceeds this limit, they will not be able to borrow more stablecoins.

## Any pertinent formulas used.
The system uses a few key formulas:

The system uses a formula to calculate the amount of stablecoins a user can borrow. This formula takes into account the user's collateral and the total debt of the protocol.
The system uses a formula to calculate the fee for a user's position. This formula takes into account the amount of stablecoins borrowed and the time elapsed since the borrowing.
The system uses a formula to calculate the USD price for tokens. This formula takes into account the price feed for the token and the amount of tokens.

## What is the paradox described? What is your decision to address it and why?
In the Crab system, the interest for the borrowed stablecoins is paid back in the form of a fee. This fee is typically a percentage of the borrowed amount, and it goes to the system itself, not to any specific user. The system can use these fees to maintain its operations, such as paying for transaction processing and system upgrades.

The stablecoins that must pay back the interest come from the system's reserves. When a user borrows stablecoins, the system mints new stablecoins and sends them to the user. When the user repays the borrowed stablecoins, the system burns the repaid stablecoins and returns the collateral to the user. The system's reserves are made up of the collateral deposited by users, so they are always available to cover the total debt.

As for whether there is more than $1 of debt for every circulating stablecoin, this depends on the total value of the collateral deposited and the total amount of stablecoins in circulation. If the total value of the collateral is greater than the total amount of stablecoins, then there is indeed more than $1 of debt for every circulating stablecoin. However, the system uses a formula to calculate the amount of stablecoins a user can borrow, which takes into account the user's collateral and the total debt of the protocol. This formula ensures that the system maintains a 1 token == $1 peg at all times.

Finally, whether there are enough stablecoins in circulation to pay back all debt at any given time depends on the total value of the collateral deposited. If the total value of the collateral is equal to or greater than the total amount of stablecoins in circulation, then there are indeed enough stablecoins in circulation to pay back all debt. However, the system uses a formula to calculate the amount of stablecoins a user can borrow, which takes into account the user's collateral and the total debt of the protocol. This formula ensures that the system maintains a 1 token == $1 peg at all times

# Claw Governance
The ClawGovernanceCoin contract is a governance token that allows users to propose and vote on proposals. Users interact with the contract by calling the propose function to propose a new proposal and the vote function to vote on a proposal.

The propose function creates a new proposal and automatically votes for it. The vote function allows a user to vote on a proposal. It checks that the proposal has not ended and that the user has not already voted on the proposal before recording the user's vote.

## What actors are involved? Is there a keeper? What is the admin tasked with?
The main actors involved in the system are the users, who are the holders of the ClawGovernanceCoin tokens. Users can propose and vote on proposals.

The contract owner is also an actor in the system. The contract owner has the ability to burn and mint tokens, which are administrative tasks. The contract owner can burn tokens to reduce the total supply and mint new tokens to increase the total supply.

There is no keeper involved in the system. The term "keeper" is often used in the context of DeFi protocols to refer to a service that automatically performs certain actions on behalf of the users, such as rebalancing a portfolio or lending assets. In this system, the users have to perform these actions manually.

## What are the known risks/issues?
The main risk in this system is the potential for Sybil attacks. In a Sybil attack, a user creates multiple fake identities and uses them to control the majority of the votes. To mitigate this risk, the system requires that a user holds more than 1% of the total supply of tokens to propose a new proposal. This requirement prevents a user from controlling a majority of the votes through Sybil attacks.

Another potential issue is that the system does not prevent a user from voting more than once on the same proposal. This could be a problem if the voting system is not designed to handle multiple votes from the same user. To mitigate this issue, the system checks that a user has not already voted on a proposal before recording the user's vote.

## Any pertinent formulas used.

The contract uses a few important formulas to manage the voting process:

1. **Proposal Creation**: When a user proposes a new proposal, the contract checks if the user holds more than 1% of the total supply of tokens. This is done using the formula `totalTokenBalanceForSender > onePercentTotalSupplyOfToken`.

2. **Voting**: When a user votes on a proposal, the contract checks if the proposal has not ended and if the user has not already voted on the proposal. The end time of the proposal is calculated as `block.timestamp + 5 days`.

3. **Token Burning**: When the contract owner burns tokens, the contract checks if the amount to burn is more than zero and if the owner has enough tokens to burn. The amount to burn is checked with the formula `balance < _amount`.

4. **Token Minting**: When the contract owner mints new tokens, the contract checks if the recipient address is not zero and if the amount to mint is more than zero. The amount to mint is checked with the formula `_amount <= 0`.

These formulas are used to ensure that the contract behaves as expected and to prevent certain actions from being performed, such as voting on an ended proposal or burning or minting tokens with an invalid amount
