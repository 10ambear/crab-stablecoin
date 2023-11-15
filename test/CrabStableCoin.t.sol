// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import "../src/CrabStableCoin.sol";

contract CrabStableCoinTest is Test {
   CrabStableCoin public crabStableCoin;
   address owner;

   function setUp() public {
       crabStableCoin = new CrabStableCoin();
   }

   function testMint() public {
       uint256 initialBalance = crabStableCoin.balanceOf(address(this));
       crabStableCoin.mint(address(this), 100);
       uint256 finalBalance = crabStableCoin.balanceOf(address(this));
       assertEq(finalBalance, initialBalance + 100);
   }

   function testBurn() public {
       crabStableCoin.mint(address(this), 100);
       uint256 initialBalance = crabStableCoin.balanceOf(address(this));
       crabStableCoin.burn(50);
       uint256 finalBalance = crabStableCoin.balanceOf(address(this));
       assertEq(finalBalance, initialBalance - 50);
   }
}
