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

    uint256 amountOfWethCollateral = 15 ether;
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
        // Mint some tokens for the user 15e18
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

        // user withdraws the collateral
        vm.startPrank(user);
        uint256 withdrawAmount = 10e18;
        crabEngine.withdrawCollateral(weth, withdrawAmount);
        vm.stopPrank();

        // check if the collateral has been removed from the crab engine
        uint256 collateralAfterWithdrawal = crabEngine.s_collateralDeposited(user, weth);
        assertEq(collateralAfterWithdrawal, amountOfWethCollateral-withdrawAmount);
    }
    // not working atm
    // i.e. if the user has borrowed something
    function testWithdrawCollateralWithBorrowedAmount() public {
        uint256 amountOfCrabTheUserWantsToBorrow = 2e18;
        // Mint some tokens for the user 15e18
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

        // at this point the user has collateral, now they need to borrow some crab
        vm.startPrank(user);
        crabEngine.borrow(amountOfCrabTheUserWantsToBorrow);
        vm.stopPrank();

        // now the user should have their crab, let's check if they have it
        uint256 amountOfCrabBorrowed = crabEngine.getUserCrabBalance(user);
        assertEq(amountOfCrabBorrowed, amountOfCrabTheUserWantsToBorrow);
        
        // // user withdraws the collateral 
        vm.startPrank(user);
        uint256 withdrawAmount = 2e18;
        crabEngine.withdrawCollateral(weth, withdrawAmount);
        vm.stopPrank();

        // // // check if the collateral has been removed from the crab engine
        uint256 collateralAfterWithdrawal = crabEngine.s_collateralDeposited(user, weth);
        assertEq(collateralAfterWithdrawal, amountOfWethCollateral-withdrawAmount);
    }

    ///////////////////////////////////////
    // Borrow Tests //
    ///////////////////////////////////////
    function testBorrow() public {
        // deposit funds
        MockERC20(weth).mint(user, amountOfWethCollateral);
        vm.startPrank(user);
        MockERC20(weth).approve(address(crabEngine), amountOfWethCollateral);
        crabEngine.depositCollateral(weth, amountOfWethCollateral);

        // test first borrow
        vm.warp(block.timestamp + 12 seconds);        
        uint256 borrowAmount = 1e18;
        crabEngine.borrow(borrowAmount);
        assertEq(crabStableCoin.balanceOf(user), borrowAmount);

        // test to see if second borrow would increase balance
        vm.warp(block.timestamp + 12 seconds);
        crabEngine.borrow(borrowAmount);
        assertEq(crabStableCoin.balanceOf(user), 2 * borrowAmount);

        // attempt to borrow a third time
        vm.warp(block.timestamp + 12 seconds);
        vm.expectRevert("User has already borrowed the allowed amount of times/value.");
        crabEngine.borrow(borrowAmount);
        
        vm.stopPrank();
    }

    function testMaximumBorrow() public {
        // deposit funds
        MockERC20(weth).mint(user, 1 ether);
        vm.startPrank(user);
        MockERC20(weth).approve(address(crabEngine), 1 ether);
        crabEngine.depositCollateral(weth, 1 ether);

        // attempt to borrow the exact amount should revert due to < instead of <=
        uint256 maximumBorrow = crabEngine.getTotalBorrowableAmount();
        vm.expectRevert("Amount exceeds collateral borrow value");
        crabEngine.borrow(maximumBorrow);
        
        // attempt to borrow 1 less than the max
        vm.warp(block.timestamp + 12 seconds);
        crabEngine.borrow(maximumBorrow - 1);
        assertEq(crabStableCoin.balanceOf(user), maximumBorrow - 1); 

        // attempt to borrow again now that max has been reached
        vm.warp(block.timestamp + 12 seconds);
        vm.expectRevert("Amount exceeds collateral borrow value");
        crabEngine.borrow(1);

        vm.stopPrank();
    }


    ///////////////////////////////////////
    // Repay Tests //
    ///////////////////////////////////////
    function testRepay() public {
        // deposit funds
        MockERC20(weth).mint(user, 1 ether);

        // give the user funds to pay back
        uint256 feeAfter12Days = 3_287_671_232_486_400;
        vm.prank(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
        crabStableCoin.mint(user, feeAfter12Days);

        vm.startPrank(user);
        MockERC20(weth).approve(address(crabEngine), 1 ether);
        crabEngine.depositCollateral(weth, 1 ether);

        
        vm.warp(block.timestamp + 12 seconds);
        crabEngine.borrow(1 ether);
        
        // total that must be returned = 1_003_287_671_232_486_400
        uint256 userBalance = crabStableCoin.balanceOf(user);
        
        vm.warp(block.timestamp + 12 days);        
        vm.expectRevert("Insufficient borrowed amount");
        crabEngine.repay(userBalance + 1);

        vm.expectRevert("User must payback the EXACT amount owed.");
        crabEngine.repay(userBalance - 1);

        crabStableCoin.approve(address(crabEngine), userBalance);
        crabEngine.repay(userBalance);
        assertEq(crabStableCoin.balanceOf(user), 0);

        vm.stopPrank();
    }

    

}
