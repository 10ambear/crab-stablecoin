// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface ILiquidationCallback {

    /**
     * @dev Called upon receiving collateral from a position during liquidation
     * Swaps the received collateral to the protocol stablecoin.
     * Sends the necessary stablecoins to the liquidator so they may repay the position's debt.
     */
    function onCollateralReceived(address collateralToken, uint256 collateralAmount) external;
}