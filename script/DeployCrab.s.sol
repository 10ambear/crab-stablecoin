// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { CrabStableCoin } from "../src/CrabStableCoin.sol";
import { CrabEngine } from "../src/CrabEngine.sol";

contract DeployCrab is Script {

    // function run() external returns (CrabStableCoin, CrabEngine, HelperConfig) {
    //     HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!

    //     (
    //         address wethUsdPriceFeed,
    //         address usdcUsdPriceFeed,
    //         address solUsdPriceFeed,
    //         uint256 deployerKey
    //     ) = helperConfig.activeNetworkConfig();

    //     vm.startBroadcast(deployerKey);
    //     CrabStableCoin crab = new CrabStableCoin();
    //     CrabEngine crabEngine = new CrabEngine(
    //         address(crab),
    //         priceFeedAddresses,
    //         tvlRatios,
    //         address(crab)
    //     );
    //     crab.transferOwnership(address(crabEngine));
    //     vm.stopBroadcast();
    //     return (crab, crabEngine, helperConfig);
    // }
}
