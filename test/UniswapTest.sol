// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { CrabStableCoin } from "../src/CrabStableCoin.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapTest is Test {
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    CrabStableCoin public crabStablecoin;

    IERC20 public constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public constant usdcWhale = 0xDa9CE944a37d218c3302F6B82a094844C6ECEb17;
    address public constant wethWhale = 0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3;
    address public constant daiWhale = 0x60FaAe176336dAb62e284Fe19B885B095d29fB7F;

    function setUp() public {
        vm.prank(owner);
        crabStablecoin = new CrabStableCoin();
    }

    function _mint(IERC20 token, address to, uint256 amount) internal {
        if (address(token) == address(crabStablecoin)) {
            crabStablecoin.mint(to, amount);
            return;
        }

        if (token == usdc) {
            vm.prank(usdcWhale);
        } else if (token == weth) {
            vm.prank(wethWhale);
        } else if (token == dai) {
            vm.prank(daiWhale);
        } else {
            revert("<WRONG TOKEN>");
        }

        IERC20(token).transfer(to, amount);
    }

    function test_uniswapSwapCrabForUsdc() public { 
        uint256 bobUsdcBalInitial = usdc.balanceOf(bob);

        assertTrue(bobUsdcBalInitial == 0); 

        // usdc has 6 decimals
        _mint(usdc, bob, 10*1e6);

        uint256 bobUsdcBalAfter = usdc.balanceOf(bob); 
        assertTrue(bobUsdcBalAfter == 10*1e6);
    }
}
