// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { Test, console } from "forge-std/Test.sol";
import { CrabStableCoin } from "../src/CrabStableCoin.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISwapRouter } from "./interfaces/ISwapRouter.sol";
import { IUniswapV3Pool } from "./interfaces/IUniswapV3Pool.sol";
import { IUniswapV3Factory } from "./interfaces/IUniswapV3Factory.sol";

contract UniswapTest is Test {
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    CrabStableCoin public crabStablecoin;

    IUniswapV3Factory public constant uniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter public constant uniswapV3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IERC20 public constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public constant usdcWhale = 0xDa9CE944a37d218c3302F6B82a094844C6ECEb17;
    address public constant wethWhale = 0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3;
    address public constant daiWhale = 0x60FaAe176336dAb62e284Fe19B885B095d29fB7F;

    IUniswapV3Pool public crabDaiPool;

    function setUp() public {
        crabStablecoin = new CrabStableCoin();

        // we're only creating one pool since it allows us to use the
        // liquiditiy from the DAI pool to swop to others using the router
        crabDaiPool = IUniswapV3Pool(uniswapV3Factory.createPool(address(crabStablecoin), address(dai), 500));

        console.log("DAI 0: ", crabDaiPool.token0()); // DAI
        console.log("CRAB 1: ", crabDaiPool.token1()); // CRAB

        // Uniswap sqrtPriceX96 = √price * 2^96
        // since 1 dai should equal 1 crab,
        // sqrtPriceX96 should be √1 * 2^96
        // since √1 = 1, sqrtPriceX96 should be 2^96
        uint160 initialPrice = 79_228_162_514_264_337_593_543_950_336;

        // initial price
        // initial liquidity amount
        // DAI is token 0, CRAB is token 1
        crabDaiPool.initialize(initialPrice);

        // this is to check that the pool is zero
        (, int24 tick,,,,,) = crabDaiPool.slot0();
        console.log("tick:");
        console.logInt(tick);
    }

    // DAI is token 0, CRAB is token 1
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) public {
        //vm.prank(owner);
        _mint(crabStablecoin, msg.sender, amount1);
        _mint(dai, msg.sender, amount0);
        console.log("Minted Amount 0:", amount0);
        console.log("Minted Amount 1:", amount1);
    }

    function mintLiquidity() public {
        int24 lowerTick = -50;
        int24 upperTick = 50;
        // Provide liquidity for the new Uniswap pair, concentrate the liquidity around $1
        // L = 400 * amount of token0/token1 needed
        // 25mil DAI & 25mil CRAB to provide liquidity to the pool
        crabDaiPool.mint(address(this), lowerTick, upperTick, 1e28, "");
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
        _mint(usdc, bob, 10 * 1e6);

        uint256 bobUsdcBalAfter = usdc.balanceOf(bob);
        assertTrue(bobUsdcBalAfter == 10 * 1e6);

        mintLiquidity();

        // get an address that has the initial 10 crab
        _mint(crabStablecoin, bob, 10 * 1e18);

        // approve the router to spend the crab
        vm.prank(bob);
        crabStablecoin.approve(address(uniswapV3Router), 10 * 1e18);

        // create a path from crab to usdc
        bytes memory path = bytes.concat(
            bytes20(address(crabStablecoin)),
            bytes3(uint24(500)), // fee tier for the pool is 0.05%
            bytes20(address(dai)),
            bytes3(uint24(3000)), // fee tier for the dai-weth pool is 0.30%
            bytes20(address(weth))
        );

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: bob,
            deadline: block.timestamp,
            amountIn: 10 * 1e18,
            amountOutMinimum: 9 * 1e6
        });

        // Perform swap
        uniswapV3Router.exactInput(params);

        assertTrue(crabStablecoin.balanceOf(bob) == 0); 
        assertTrue(usdc.balanceOf(bob) >= 99 * 1e5); // 0.99 USDC received
        assertTrue(usdc.balanceOf(bob) < 10 * 1e6); // Didn't quite get a full USDC due to fees & slippage
    }

    function test_uniswapSwapForWeth() public {
        mintLiquidity();
        _mint(crabStablecoin, bob, 10 * 1e18);
        vm.startPrank(bob);

        assertTrue(crabStablecoin.balanceOf(bob) == 10*1e18);
        assertTrue(weth.balanceOf(bob) == 0);

        // Approve the router
        crabStablecoin.approve(address(uniswapV3Router), type(uint256).max);

        // Let's swap crab to USDC
        bytes memory path = bytes.concat(
            bytes20(address(crabStablecoin)),
            bytes3(uint24(500)), // fee tier for the pool is 0.05%
            bytes20(address(dai)),
            bytes3(uint24(3000)), // fee tier for the dai-weth pool is 0.30%
            bytes20(address(weth))
        );

        // 10 / 2,000 = 0.005 ETH = 5 * 1e15
        // Should expect roughly 5 * 1e15 out

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: bob,
            deadline: block.timestamp,
            amountIn: 10 * 1e18,
            amountOutMinimum: 49 * 1e13 // depends on current price of ETH, should get roughly 1/2,000 = 0.0005 ETH at current prices
        });

        // Perform swap
        uniswapV3Router.exactInput(params);

        assertTrue(crabStablecoin.balanceOf(bob) == 0);
        assertTrue(weth.balanceOf(bob) >= 49 * 1e14); // More than 0.0049 ETH received
        assertTrue(weth.balanceOf(bob) < 51 * 1e14); // Less than 0.0051 ETH received
    }

}
