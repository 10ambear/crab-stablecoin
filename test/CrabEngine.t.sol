// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "../src/CrabEngine.sol";
import "../src/CrabStableCoin.sol";
import "../src/ClawGovernanceCoin.sol";
import "../src/ClawGovernanceStaking.sol";
import { Test, console } from "forge-std/Test.sol";
import { DeployCrab } from "../script/DeployCrab.s.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
//import "./mocks/MockV3Aggregator.sol";

contract CrabEngineTest is Test {
    address public constant usdcWhale = 0xDa9CE944a37d218c3302F6B82a094844C6ECEb17;
    address public constant wethWhale = 0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3;
    address public constant daiWhale = 0x60FaAe176336dAb62e284Fe19B885B095d29fB7F;

    DeployCrab crabDeployer;
    CrabStableCoin crabStableCoin;
    CrabEngine crabEngine;
    ClawGovernanceCoin clawCoin;
    ClawGovernanceStaking clawStake;
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
        (crabStableCoin, crabEngine, clawCoin, clawStake, helperConfig) = crabDeployer.run();
        (wethUsdPriceFeed, weth,,,,,) = helperConfig.activeNetworkConfig();
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

    ///////////////////////////////////////
    // uniswap stuffs //
    ///////////////////////////////////////

    function test_uniswapSwapCrabForUsdc() public {
        address bob = makeAddr("bob");
        MockERC20(weth).mint(bob, 10e18);
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
        assertEq(collateralAfterWithdrawal, amountOfWethCollateral - withdrawAmount);
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
        assertEq(collateralAfterWithdrawal, amountOfWethCollateral - withdrawAmount);
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

        // test to see if current borrowed + new borrowed will exceed maxBorrow
        vm.warp(block.timestamp + 12 seconds);
        uint256 maximumBorrow = crabEngine.getTotalBorrowableAmount();
        vm.expectRevert("Amount exceeds collateral borrow value");
        crabEngine.borrow(maximumBorrow);

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
        MockERC20(weth).mint(user, 15 ether);

        // Approve the CrabEngine contract to spend the user's tokens
        vm.startPrank(user);
        MockERC20(weth).approve(address(crabEngine), 2 ether);
        crabEngine.depositCollateral(weth, 1 ether);

        vm.warp(block.timestamp + 12 seconds);
        crabEngine.borrow(1 ether);

        // attempt to pay without calculating fee
        vm.expectRevert("Stale fee. Refresh fee by calling getUserOwedAmount first.");
        crabEngine.repay(1);

        crabEngine.getUserOwedAmount();

        // attempt to pay after exceeding heartbeat
        vm.warp(block.timestamp + 12 days);
        vm.expectRevert("Stale fee. Refresh fee by calling getUserOwedAmount first.");
        crabEngine.repay(1);
        uint256 owedAmount = crabEngine.getUserOwedAmount();
        vm.stopPrank();

        // give the user funds to pay back
        vm.prank(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
        crabStableCoin.mint(user, owedAmount);

        // pay properly
        vm.startPrank(user);
        crabStableCoin.approve(address(crabEngine), owedAmount);
        crabEngine.repay(owedAmount);

        vm.stopPrank();
    }

    ///////////////////////////////////////
    // liquidate Tests //
    ///////////////////////////////////////

    function setUpLiqiudate() public {
        uint256 collateral = 15 ether;
        // Mint some tokens for the user 15e18
        MockERC20(weth).mint(user, collateral);

        // Approve the CrabEngine contract to spend the user's tokens
        vm.startPrank(user);
        MockERC20(weth).approve(address(crabEngine), collateral);

        // transfer the user's tokens to the crabengine
        crabEngine.depositCollateral(weth, collateral);
        vm.stopPrank();

        // Check if the user's collateral deposited was updated correctly
        uint256 userCollateralDeposited = crabEngine.s_collateralDeposited(user, weth);
        assertEq(userCollateralDeposited, amountOfWethCollateral);

    }

    function testLiquidate() public {
        // Setup: Mint some tokens for the user and deposit them as collateral
        // ...

        // Test 1: User has no debt
        // ...

        // Test 2: User's collateral value is insufficient to cover the debt
        // ...

        // Test 3: User's collateral value is sufficient to cover the debt
        // ...
    }

    function testUserHasNoDebt() public {
        // Setup: Set the user's debt to 0
        // ...

        // Call the liquidate function
       

        // Check that the function reverts with the correct error message
        
    }

    function testInsufficientCollateral() public {
        // Setup: Set the user's debt to a value greater than their collateral value
        // ...

        // Call the liquidate function

        // Check that the function reverts with the correct error message
    }

    function testSufficientCollateral() public {
        // Setup: Set the user's debt to a value less than or equal to their collateral value
        // ...

        // Call the liquidate function
        
        // Check that the state of the contract is updated correctly
        // ...
    }

    ///////////////////////////////////////
    // Staker Tests //
    ///////////////////////////////////////
    function testStakeUnstake() public {
        uint256 coinBalance = 10;
        uint256 singularStake = coinBalance / 2;

        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        clawCoin.mint(user, coinBalance);

        address user2 = address(2);
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        clawCoin.mint(user2, coinBalance);

        vm.startPrank(user);
        vm.expectRevert("Amount must be more than 0");
        clawStake.stake(0);

        vm.expectRevert("Not enough funds");
        clawStake.stake(coinBalance + 1);

        // test first stake no if
        clawCoin.approve(address(clawStake), singularStake);
        clawStake.stake(singularStake);
        assertEq(singularStake, clawStake.getTotalStakedAmount());
        assertEq(singularStake, clawStake.getStake(user));

        // test if
        clawCoin.approve(address(clawStake), singularStake);
        clawStake.stake(singularStake);
        assertEq(coinBalance, clawStake.getTotalStakedAmount());
        assertEq(coinBalance, clawStake.getStake(user));
        vm.stopPrank();

        // test 2nd user stake
        vm.startPrank(user2);
        clawCoin.approve(address(clawStake), singularStake);
        clawStake.stake(singularStake);
        assertEq(singularStake * 3, clawStake.getTotalStakedAmount());
        assertEq(singularStake, clawStake.getStake(user2));
        vm.stopPrank();

        // test first user unstake
        vm.startPrank(user);
        vm.expectRevert("Amount must be more than 0");
        clawStake.unstake(0);

        vm.expectRevert("Amount must be more than 0");
        clawStake.unstake(0);

        // test if user can unstake twice
        clawStake.unstake(singularStake);
        assertEq(singularStake * 2, clawStake.getTotalStakedAmount());
        assertEq(singularStake, clawStake.getStake(user));

        clawStake.unstake(singularStake);
        assertEq(singularStake, clawStake.getTotalStakedAmount());
        assertEq(0, clawStake.getStake(user));
    }
}
