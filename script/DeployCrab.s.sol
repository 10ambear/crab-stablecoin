// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { CrabStableCoin } from "../src/CrabStableCoin.sol";
import { CrabEngine } from "../src/CrabEngine.sol";

contract DeployCrab is Script {

    address[] tokenAddresses;
    address[] priceFeedAddresses;
    uint8[] priceFeedDecimals;
    uint8[] tvlRatios;


    function run() external returns (CrabStableCoin, CrabEngine, HelperConfig) {
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
        CrabStableCoin crabStableCoin = new CrabStableCoin();
        CrabEngine crabEngine = new CrabEngine(
            tokenAddresses,
            priceFeedAddresses,
            priceFeedDecimals,
            tvlRatios,
            address(crabStableCoin)
        );

        // transfer the stablecoin ownership to the crabEngine
        crabStableCoin.transferOwnership(address(crabEngine));
        vm.stopBroadcast();
        return (crabStableCoin, crabEngine, helperConfig);
    }
}
