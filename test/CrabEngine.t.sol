// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "../src/CrabEngine.sol";
import "../src/CrabStableCoin.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployCrab} from "../script/DeployCrab.s.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
//import "./mocks/MockV3Aggregator.sol";


contract CrabEngineTest is Test {
    DeployCrab crabDeployer;
    CrabStableCoin crabStableCoin;
    CrabEngine crabEngine;
    HelperConfig helperConfig;
    address wethUsdPriceFeed;
    address weth;
    address usdcUsdPriceFeed;
    address usdc;

    uint256 amountCollateral = 10 ether;
    address public user = address(1);
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        crabDeployer = new DeployCrab();
        (crabStableCoin, crabEngine, helperConfig) = crabDeployer.run();
        (wethUsdPriceFeed, weth, , , , , ) = helperConfig.activeNetworkConfig();
        vm.deal(user, STARTING_USER_BALANCE);
    }

    ///////////////////////
    // Constructor Tests //
    ///////////////////////
    address[] public tokenAddresses;
    address[] public feedAddresses;
    uint8[] priceFeedDecimals;
    uint8[] tvlRatios;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(wethUsdPriceFeed);
        feedAddresses.push(usdcUsdPriceFeed);
        priceFeedDecimals.push(8);
        tvlRatios.push(50);

        vm.expectRevert(CrabEngine.CrabEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch.selector);
        new CrabEngine(tokenAddresses, feedAddresses, priceFeedDecimals,tvlRatios, address(crabEngine));
    }

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        // 15e18 * $2000 = 30_000e18
        uint256 expectedUSDValue = 30_000e18;
        uint256 actualUSDValue = crabEngine.getPriceInUSDForTokens(weth, ethAmount);
        assertEq(expectedUSDValue, actualUSDValue);
    }

    function testDepositCollateral() public {

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
