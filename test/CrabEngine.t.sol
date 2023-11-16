// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "../src/CrabEngine.sol";
import "forge-std/Test.sol";

contract CrabEngineTest is Test {
  CrabEngine public crabEngine;
  address eth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        // Initialize the CrabStableCoin contract
        CrabStableCoin crabStableCoin = new CrabStableCoin();

        // Store the address of the CrabStableCoin contract
        address crabStableCoinAddress = address(crabStableCoin);

        // Initialize the CrabEngine contract with your constructor arguments
        address[] memory tokenAddresses = new address[](3);
        tokenAddresses[0] = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
        tokenAddresses[1] = 0x8267cF9254734C6Eb452a7bb9AAF97B392258b21;
        tokenAddresses[2] = 0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6;

        // sepolia testnet addresses
        address[] memory priceFeedAddresses = new address[](3);
        priceFeedAddresses[0] =0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeedAddresses[1] = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
        // this is a dai usd price feed since there's no chainlink sol feed on sepolia testnet
        // I could be wrong, but I couldn't see one
        priceFeedAddresses[2] = 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;

        uint256[] memory tvlRatios = new uint256[](3);
        tvlRatios[0] = 70; // LTV ratio for ETH
        tvlRatios[1] = 80; // LTV ratio for USDC
        tvlRatios[2] = 50; // LTV ratio for SOL

        crabEngine = new CrabEngine(tokenAddresses, priceFeedAddresses, tvlRatios, crabStableCoinAddress);
    }

    function testDepositCollateral() public {
        // // Arrange
        // address collateralToken = /* address of collateral token */;
        // uint256 amount = /* amount to deposit */;

        // // Act
        // crabEngine.depositCollateral(collateralToken, amount);

        // // Assert
        // assertEq(crabEngine.s_collateralDeposited(msg.sender, collateralToken), amount);
    }

    function testWithdrawCollateral() public {
        // // Arrange
        // address collateralToken = /* address of collateral token */;
        // uint256 amount = /* amount to withdraw */;

        // // Act
        // crabEngine.withdrawCollateral(collateralToken, amount);

        // // Assert
        // assertEq(crabEngine.s_collateralDeposited(msg.sender, collateralToken), /* expected remaining balance */);
    }

    function testWithdrawCollateralReverts() public {
        // // Arrange
        // address collateralToken = /* address of collateral token */;
        // uint256 amount = /* amount to withdraw that would violate LTV ratio */;

        // // Act and Assert
        // vm.expectRevert("Withdrawal would violate LTV ratio");
        // crabEngine.withdrawCollateral(collateralToken, amount);
    }


}
