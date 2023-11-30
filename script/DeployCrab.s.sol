// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { CrabStableCoin } from "../src/CrabStableCoin.sol";
import { CrabEngine } from "../src/CrabEngine.sol";
import { ClawGovernanceCoin } from "../src/ClawGovernanceCoin.sol";
import { ClawGovernanceStaking } from "../src/ClawGovernanceStaking.sol";

contract DeployCrab is Script {

    address[] tokenAddresses;
    address[] priceFeedAddresses;
    uint8[] priceFeedDecimals;
    uint8[] tvlRatios;

    // moved outside of run due to stackTooDeep exception caused by num of local vars
    CrabStableCoin crabStableCoin;
    CrabEngine crabEngine;
    ClawGovernanceCoin clawCoin;
    ClawGovernanceStaking clawStake;

    function run() external returns (CrabStableCoin, CrabEngine, ClawGovernanceCoin, ClawGovernanceStaking, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            address wethUsdPriceFeed,
            address weth,
            address usdcUsdPriceFeed,
            address usdc,
            address solUsdPriceFeed,
            address sol,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        // we're doing this to fill the constructor in the crabEngine
        tokenAddresses = [weth, usdc, sol];
        priceFeedAddresses = [wethUsdPriceFeed, usdcUsdPriceFeed, solUsdPriceFeed];
        priceFeedDecimals = [18, 8, 8];
        tvlRatios = [70, 80, 50];

        vm.startBroadcast(deployerKey);
        crabStableCoin = new CrabStableCoin();
        crabEngine = new CrabEngine(
            tokenAddresses,
            priceFeedAddresses,
            priceFeedDecimals,
            tvlRatios,
            address(crabStableCoin)
        );

        // transfer the stablecoin ownership to the crabEngine
        crabStableCoin.transferOwnership(address(crabEngine));

        clawCoin = new ClawGovernanceCoin();
        clawStake = new ClawGovernanceStaking(address(clawCoin), address(crabEngine));
        clawCoin.setStakingContract(address(clawStake));

        vm.stopBroadcast();
        return (crabStableCoin, crabEngine, clawCoin, clawStake, helperConfig);
    }
}
