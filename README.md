# official readme

# How does the system work? How would a user interact with it?
The system is a decentralized stablecoin system called Crab. It is designed to maintain a 1 token == $1 peg at all times. The system allows users to deposit collateral, borrow stablecoins, and repay borrowed stablecoins. The system is based on the MakerDAO DSS system.

Users interact with the system through the following functions:

- depositCollateral: Users can deposit collateral into their position. Only supported collateral tokens are allowed.
- withdrawCollateral: Users can withdraw collateral from their position.
- borrow: Users can borrow protocol stablecoins against their collateral.
- repay: Users can repay protocol stablecoins from their debt.

# What actors are involved? Is there a keeper? What is the admin tasked with?
There are two main actors involved in the system:

Users: They interact with the system by depositing collateral, borrowing stablecoins, and repaying borrowed stablecoins.
Owner: The Owner is responsible for setting up the system, adding coins and feeds, and managing the protocol.

# What are the known risks/issues?
The system has a few known risks and issues:

The system relies on external price feeds for collateral tokens. If these price feeds are manipulated or inaccurate, it could lead to a loss of funds for users.
The system has a limit on the number of times a user can borrow. If a user exceeds this limit, they will not be able to borrow more stablecoins.

# Any pertinent formulas used.
The system uses a few key formulas:

The system uses a formula to calculate the amount of stablecoins a user can borrow. This formula takes into account the user's collateral and the total debt of the protocol.
The system uses a formula to calculate the fee for a user's position. This formula takes into account the amount of stablecoins borrowed and the time elapsed since the borrowing.
The system uses a formula to calculate the USD price for tokens. This formula takes into account the price feed for the token and the amount of tokens.

# What is the paradox described? What is your decision to address it and why?
In the Crab system, the interest for the borrowed stablecoins is paid back in the form of a fee. This fee is typically a percentage of the borrowed amount, and it goes to the system itself, not to any specific user. The system can use these fees to maintain its operations, such as paying for transaction processing and system upgrades.

The stablecoins that must pay back the interest come from the system's reserves. When a user borrows stablecoins, the system mints new stablecoins and sends them to the user. When the user repays the borrowed stablecoins, the system burns the repaid stablecoins and returns the collateral to the user. The system's reserves are made up of the collateral deposited by users, so they are always available to cover the total debt.

As for whether there is more than $1 of debt for every circulating stablecoin, this depends on the total value of the collateral deposited and the total amount of stablecoins in circulation. If the total value of the collateral is greater than the total amount of stablecoins, then there is indeed more than $1 of debt for every circulating stablecoin. However, the system uses a formula to calculate the amount of stablecoins a user can borrow, which takes into account the user's collateral and the total debt of the protocol. This formula ensures that the system maintains a 1 token == $1 peg at all times.

Finally, whether there are enough stablecoins in circulation to pay back all debt at any given time depends on the total value of the collateral deposited. If the total value of the collateral is equal to or greater than the total amount of stablecoins in circulation, then there are indeed enough stablecoins in circulation to pay back all debt. However, the system uses a formula to calculate the amount of stablecoins a user can borrow, which takes into account the user's collateral and the total debt of the protocol. This formula ensures that the system maintains a 1 token == $1 peg at all times

