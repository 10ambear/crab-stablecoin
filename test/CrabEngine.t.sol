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


    function setUp() public {
        crabDeployer = new DeployCrab();
        (crabStableCoin, crabEngine, helperConfig) = crabDeployer.run();
        (wethUsdPriceFeed, weth, , , , , ) = helperConfig.activeNetworkConfig();
    }

    // function _getPriceInUSDForTokens(address token, uint256 tokenAmount) public view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(s_collateralTokenData[token].priceFeedAddress);
    //     (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
    //     //TEST IDEA fuzz this line here
    //     return ((uint256(price) * EQUALIZER_PRECISION) * tokenAmount) / PRECISION;
    // }

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        // 15e18 * $2000 = 30_000e18
        uint256 expectedUSDValue = 30_000e18;
        uint256 actualUSDValue = crabEngine.getPriceInUSDForTokens(weth, ethAmount);
        assertEq(expectedUSDValue, actualUSDValue);
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
