// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { MockV3Aggregator } from "../test/mocks/MockV3Aggregator.sol";
import { Script } from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "forge-std/console.sol";

// mock erc20 token
contract ERC20Mock is ERC20 {
   constructor (
       string memory name,
       string memory symbol,
       address initialAccount,
       uint256 initialBalance
   ) ERC20(name, symbol) {
       _mint(initialAccount, initialBalance);
   }
}

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 18;
    // these are obviously not accurate
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant USDC_USD_PRICE = 1000e8;
    int256 public constant SOL_USD_PRICE = 500e8;

    struct NetworkConfig {
        address wethUsdPriceFeed;
        address usdcUsdPriceFeed;
        address solUsdPriceFeed;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        console.log("HELPER CONFIG PRE IF");
        if (block.chainid == 11_155_111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            console.log("HELPER CONFIG IN ELSE");
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            usdcUsdPriceFeed: 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E,
            // // this is a dai usd price feed since there's no chainlink sol feed on sepolia testnet
            // // I could be wrong, but I couldn't see one, so we're going to pretend
            solUsdPriceFeed: 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // Check to see if we set an active network config
        if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator EthUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            ETH_USD_PRICE
        );
        ERC20Mock wethMock = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);


        MockV3Aggregator UsdcUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            USDC_USD_PRICE
        );
        ERC20Mock usdcMock = new ERC20Mock("USDC", "USDC", msg.sender, 1000e8);

        MockV3Aggregator SolUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            SOL_USD_PRICE
        );
        ERC20Mock solMock = new ERC20Mock("SOL", "SOL", msg.sender, 1000e8);
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({
            wethUsdPriceFeed: address(EthUsdPriceFeed),
            //weth: address(wethMock),
            usdcUsdPriceFeed: address(UsdcUsdPriceFeed),
            //usdc: address(usdcMock),
            solUsdPriceFeed: address(SolUsdPriceFeed),
            //sol: address(solMock),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });

        console.log("HELPER CONFIG GET OR CREATE ANVIL DONE");
    }
}
