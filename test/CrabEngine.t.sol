// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "../src/CrabEngine.sol";
import "../src/CrabStableCoin.sol";
import "forge-std/Test.sol";
import {DeployCrab} from "../script/DeployCrab.s.sol";
import { HelperConfig, ERC20Mock } from "../script/HelperConfig.s.sol";
import "forge-std/console.sol";


contract CrabEngineTest is Test {
    DeployCrab public crabDeployer;
    CrabStableCoin public crabStableCoin;
    CrabEngine public crabEngine;
    HelperConfig public helperConfig;

    address[3] priceFeedAddresses;
    address[3] public tokenAddresses;
    address weth;
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether; 
    uint256 public constant USER_STARTING_BALANCE = 10 ether; 

    function setUp() public {
        crabDeployer = new DeployCrab();
        (crabStableCoin, crabEngine, helperConfig) = crabDeployer.run();
        (priceFeedAddresses[0], tokenAddresses[0],
        priceFeedAddresses[1],
        priceFeedAddresses[2],) = helperConfig.activeNetworkConfig();

        console.log(priceFeedAddresses[0]);
        //ERC20Mock(weth)._mint(USER, USER_STARTING_BALANCE);
    }

    function testGetPriceInUSDForTokens() view public {
        console.log("we getting called??????????????????? ");
        console.log("\n\n\nTEST PRICE FEED");
        console.log(priceFeedAddresses[0]);
        uint256 price = crabEngine._getPriceInUSDForTokens(tokenAddresses[0], 10);
        console.log("BITCH ASS PROBLEM I FUCKIONG GOT U ");
        console.log("AND THE DUMASS PRICE IS ", price);
        // uint256 ethAmount = 15; 
        // uint256 expectedUsd = 30_000e18;
        // uint256 actualUsd = crabEngine._getPriceInUSDForTokens(ethAmount, ethUsdPriceFeed);
        // assertEq(expectedUsd, actualUsd);
    }

    // function testRevertsIfCollateralZero() public {
    // }
    
    // function testDepositCollateral() public {
    // }

    // function testDepositCollateralReverts() public {
    // }

    // function testWithdrawCollateral() public {
    // }

    // function testWithdrawCollateralReverts() public {
    // }   

    // function testBorrow() public {
    // }

    // function testBorrowReverts() public {
    // }

    // function testRepay() public {
    // }

    // function testRepayReverts() public {
    // }



}
