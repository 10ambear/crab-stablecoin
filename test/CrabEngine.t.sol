// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "../src/CrabEngine.sol";
import "../src/CrabStableCoin.sol";
import "forge-std/Test.sol";
import {DeployCrab} from "../script/DeployCrab.s.sol";
import { HelperConfig, ERC20Mock } from "../script/HelperConfig.s.sol";
import "./mocks/MockV3Aggregator.sol";

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
        (priceFeedAddresses[0], tokenAddresses[0],) = helperConfig.activeNetworkConfig();

        //ERC20Mock(weth)._mint(USER, USER_STARTING_BALANCE);
    }

    function testGetPriceInUSDForTokens() public {
        //test get weth price
        uint256 price = crabEngine._getPriceInUSDForTokens(tokenAddresses[0], 10);
        console.log(price);

        //test get usdc price
        (ERC20Mock coin, MockV3Aggregator feed) = helperConfig.createMock("USDC", 18, 1000e8);
        crabEngine.addCoinAndFeed(address(coin), address(feed), 80, 6);
        price = crabEngine._getPriceInUSDForTokens(address(coin), 10);
        console.log(price);

        //test get sol price
        (ERC20Mock coin2, MockV3Aggregator feed2) = helperConfig.createMock("SOL", 18, 1000e8);
        crabEngine.addCoinAndFeed(address(coin2), address(feed2), 50, 18);
        price = crabEngine._getPriceInUSDForTokens(address(coin2), 10);
        console.log(price);
        //uint256 price = crabEngine._getPriceInUSDForTokens(tokenAddresses[0], 10);

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
