// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import { MockV3Aggregator } from "../test/mocks/MockV3Aggregator.sol";
import { Script } from "forge-std/Script.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { MockERC20 } from "../test/mocks/MockERC20.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant WETH_DECIMALS = 18;
    uint8 public constant USDC_DECIMALS = 8;
    uint8 public constant SOL_DECIMALS = 8;
    // these are obviously not accurate
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant USDC_USD_PRICE = 1e8;
    int256 public constant SOL_USD_PRICE = 4e8;

    struct NetworkConfig {
        address wethUsdPriceFeed;
        address weth;
        address usdcUsdPriceFeed;
        address usdc;
        address solUsdPriceFeed;
        address sol;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11_155_111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // all of these feeds are for the sepolia testnet
    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            usdcUsdPriceFeed: 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E,
            usdc: 0xf08A50178dfcDe18524640EA6618a1f965821715,
            // this is a dai usd price feed since there's no chainlink sol feed on sepolia testnet
            // I could be wrong, but I couldn't see one, so we're going to pretend
            solUsdPriceFeed: 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19,
            sol: 0x68194a729C2450ad26072b3D33ADaCbcef39D574,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // Check to see if we set an active network config
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // weth
        vm.startBroadcast();
        MockV3Aggregator wethUsdcPriceFeedAggMock = new MockV3Aggregator(
            WETH_DECIMALS,
            ETH_USD_PRICE
        );
        MockERC20 wethMock = new MockERC20("WETH", "WETH");

        // usdc
        MockV3Aggregator usdUsdcPriceFeedAggMock = new MockV3Aggregator(
            USDC_DECIMALS,
            USDC_USD_PRICE
        );
        MockERC20 usdcMock = new MockERC20("USDC", "USDC");

        // sol
        MockV3Aggregator solUsdcPriceFeedAggMock = new MockV3Aggregator(
            SOL_DECIMALS,
            SOL_USD_PRICE
        );
        MockERC20 solMock = new MockERC20("USDC", "USDC");
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: address(wethUsdcPriceFeedAggMock),
            weth: address(wethMock),
            usdcUsdPriceFeed: address(usdUsdcPriceFeedAggMock),
            usdc: address(usdcMock),
            solUsdPriceFeed: address(solUsdcPriceFeedAggMock),
            sol: address(solMock),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }

}
