// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { CrabStableCoin } from "../src/CrabStableCoin.sol";
import { CrabEngine } from "../src/CrabEngine.sol";

import "forge-std/console.sol";

contract DeployCrab is Script {
    

    function run() external returns (CrabStableCoin, CrabEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        console.log("deploycrab run");

        address[3] memory priceFeedAddresses;
        //address wethPriceFeed;
        //address usdcUsdPriceFeed;
        //address solUsdPriceFeed;
        uint256 deployerKey;
        (
            priceFeedAddresses[0],
            priceFeedAddresses[1],
            priceFeedAddresses[2],
            deployerKey
        ) = helperConfig.activeNetworkConfig();

        console.log("deploycrab after active network");
        console.log(priceFeedAddresses[0]);
        console.log();

        vm.startBroadcast(deployerKey);
        CrabStableCoin crab = new CrabStableCoin();
        CrabEngine crabEngine = new CrabEngine(
            address(crab),
            priceFeedAddresses[0], priceFeedAddresses[1], priceFeedAddresses[2]
        );

        console.log("deploycrab after start broadcast and new CrabEngine");

        crab.transferOwnership(address(crabEngine));
        vm.stopBroadcast();
        return (crab, crabEngine, helperConfig);
    }
}
