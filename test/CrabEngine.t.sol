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

    uint256 amountOfWethCollateral = 10 ether;
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

    //////////////////
    // Price Tests //
    //////////////////


    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        // 15e18 * $2000 = 30_000e18
        uint256 expectedUSDValue = 30_000e18;
        uint256 actualUSDValue = crabEngine.getPriceInUSDForTokens(weth, ethAmount);
        assertEq(expectedUSDValue, actualUSDValue);
    }

    ///////////////////////////////////////
    // depositCollateral Tests //
    ///////////////////////////////////////

    function testDepositCollateral() public {
        // Mint some tokens for the user
        MockERC20(weth).mint(user, amountOfWethCollateral);

        // Approve the CrabEngine contract to spend the user's tokens
        vm.startPrank(user);
        MockERC20(weth).approve(address(crabEngine), amountOfWethCollateral);

        // Call the depositCollateral function
        crabEngine.depositCollateral(weth, amountOfWethCollateral);
        vm.stopPrank();

        // Check if the user's collateral deposited was updated correctly
        uint256 userCollateralDeposited = crabEngine.s_collateralDeposited(user, weth);
        assertEq(userCollateralDeposited, amountOfWethCollateral);

        // Check if the tokens were transferred from the user to the contract
        uint256 contractBalance = MockERC20(weth).balanceOf(address(crabEngine));
        assertEq(contractBalance, amountOfWethCollateral);
    }


    function testRevertsIfDepositCollateralZero() public {
        vm.startPrank(user);
        MockERC20(weth).approve(address(crabEngine), amountOfWethCollateral);

        vm.expectRevert(CrabEngine.CrabEngine__NeedsMoreThanZero.selector);
        crabEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }
    
    function testRevertsWithUnapprovedCollateral() public {
        MockERC20 randomToken = new MockERC20("RANDOM", "RANDOM");
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(CrabEngine.CrabEngine__TokenNotAllowed.selector, address(randomToken)));
        crabEngine.depositCollateral(address(randomToken), amountOfWethCollateral);
        vm.stopPrank();
    }

    ///////////////////////////////////////
    // borrow Tests //
    ///////////////////////////////////////

    ///////////////////////////////////////
    // withdrawCollateral Tests //
    ///////////////////////////////////////
    // i.e if the user hasn't borrowed anything
    function testWithdrawCollateralWithNoBorrowedAmount() public {
        // Mint some tokens for the user
        MockERC20(weth).mint(user, amountOfWethCollateral);

        // Approve the CrabEngine contract to spend the user's tokens
        vm.startPrank(user);
        MockERC20(weth).approve(address(crabEngine), amountOfWethCollateral);

        // transfer the user's tokens to the crabengine
        crabEngine.depositCollateral(weth, amountOfWethCollateral);
        vm.stopPrank();

        // Check if the deposit was successful
        uint256 userCollateralDeposited = crabEngine.s_collateralDeposited(user, weth);
        assertEq(userCollateralDeposited, amountOfWethCollateral);
        console.log(userCollateralDeposited/1e18);

        // user withdraws the collateral
        vm.startPrank(user);
        uint256 withdrawAmount = 10e18;
        crabEngine.withdrawCollateral(weth, withdrawAmount);
        vm.stopPrank();

        // check if the collateral has been removed from the crab engine
        uint256 collateralAfterWithdrawal = crabEngine.s_collateralDeposited(user, weth);
        assertEq(collateralAfterWithdrawal, amountOfWethCollateral-withdrawAmount);
    }

    // i.e. if the user has borrowed something
    function testWithdrawCollateralWithBorrowedAmount() public {
        uint256 amountOfCrabTheUserWantsToBorrow = 15e18;
        // Mint some tokens for the user
        MockERC20(weth).mint(user, amountOfWethCollateral);

        // Approve the CrabEngine contract to spend the user's tokens
        vm.startPrank(user);
        MockERC20(weth).approve(address(crabEngine), amountOfWethCollateral);

        // transfer the user's tokens to the crabengine
        crabEngine.depositCollateral(weth, amountOfWethCollateral);
        vm.stopPrank();

        // Check if the deposit was successful
        uint256 userCollateralDeposited = crabEngine.s_collateralDeposited(user, weth);
        assertEq(userCollateralDeposited, amountOfWethCollateral);
        console.log(userCollateralDeposited/1e18);

        // at this point the user has collateral, now they need to borrow some crab
        // todo this doesn't work properly, it seems that the s_userBorrows[msg.sender].borrowAmount1 
        // doesn't update properly
        vm.startPrank(user);
        crabEngine.borrow(amountOfCrabTheUserWantsToBorrow);
        vm.stopPrank();

        // now the user has their crab
        uint256 userCrabBalance = crabEngine.s_userCrabBalance(user);
        assertEq(userCrabBalance, amountOfCrabTheUserWantsToBorrow);
        
        // user withdraws the collateral 
        vm.startPrank(user);
        uint256 withdrawAmount = 5e18;
        crabEngine.withdrawCollateral(weth, withdrawAmount);
        vm.stopPrank();

        // check if the collateral has been removed from the crab engine
        uint256 collateralAfterWithdrawal = crabEngine.s_collateralDeposited(user, weth);
        assertEq(collateralAfterWithdrawal, amountOfWethCollateral-withdrawAmount);
    }

    ///////////////////////////////////////
    // repay Tests //
    ///////////////////////////////////////

    

}
