// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { CrabStableCoin } from "../src/CrabStableCoin.sol";
import { CrabEngine } from "../src/CrabEngine.sol";

import "forge-std/console.sol";

contract DeployCrab is Script {
    address[3] public priceFeedAddresses;
    address[3] public tokenAddresses;
    
    // struct NetworkConfig {
    //     address wethUsdPriceFeed;
    //     address weth;
    //     address usdcUsdPriceFeed;
    //     address usdc;
    //     address solUsdPriceFeed;
    //     address sol;
    //     uint256 deployerKey;
    // }

    function run() external returns (CrabStableCoin, CrabEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        console.log("deploycrab run");

        //address wethPriceFeed;
        //address usdcUsdPriceFeed;
        //address solUsdPriceFeed;
        uint256 deployerKey;

        (priceFeedAddresses[0], tokenAddresses[0], deployerKey) = helperConfig.activeNetworkConfig();

        console.log("deploycrab after active network");
        console.log(priceFeedAddresses[0]);
        console.log();

        vm.startBroadcast(deployerKey);
        CrabStableCoin crab = new CrabStableCoin();
        CrabEngine crabEngine = new CrabEngine(
            address(crab),
            priceFeedAddresses[0],
            tokenAddresses[0]
        );


        crab.transferOwnership(address(crabEngine));
        vm.stopBroadcast();
        return (crab, crabEngine, helperConfig);
    }
}
