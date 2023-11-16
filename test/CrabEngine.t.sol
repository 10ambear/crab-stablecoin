// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "../src/CrabEngine.sol";
import "../src/CrabStableCoin.sol";
import "forge-std/Test.sol";
import {DeployCrab} from "../script/DeployCrab.s.sol";
import { HelperConfig, ERC20Mock } from "../script/HelperConfig.s.sol";


contract CrabEngineTest is Test {
    DeployCrab public crabDeployer;
    CrabStableCoin public crabStableCoin;
    CrabEngine public crabEngine;
    HelperConfig public helperConfig;

    address ethUsdPriceFeed;
    address weth;
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether; 
    uint256 public constant USER_STARTING_BALANCE = 10 ether; 

    function setUp() public {
        crabDeployer = new DeployCrab();
        (crabStableCoin, crabEngine, helperConfig) = crabDeployer.run();
        (ethUsdPriceFeed, , , weth, , ,) = helperConfig.activeNetworkConfig();
        //ERC20Mock(weth)._mint(USER, USER_STARTING_BALANCE);
    }

    function testGetPriceInUSDForTokens() public {
        // uint256 ethAmount = 15; 
        // uint256 expectedUsd = 30_000e18;
        // uint256 actualUsd = crabEngine._getPriceInUSDForTokens(ethAmount, ethUsdPriceFeed);
        // assertEq(expectedUsd, actualUsd);
    }

    function testRevertsIfCollateralZero() public {
    }
    
    function testDepositCollateral() public {
    }

    function testWithdrawCollateral() public {
    }

    function testWithdrawCollateralReverts() public {
    }


}
