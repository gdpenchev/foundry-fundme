// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

//deploy mocks for testing on anvil locally
//keep track of contracts addresses across different chains
//Sopolia/USDT...ETH/USD

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeeds; //eth/usd price feed;
    }

    constructor() {
        if (block.chainid == 11155111) {
            // global variable contains the chainID, every blockchain has , eth is 1, sepolia is 11155111
            //activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // function getSepoliaEthConfig() public pure returns (NetworkConfig memory) { // By specifying memory, you tell Solidity to create a temporary instance of the struct for use within the function and its return.
    //     NetworkConfig memory sepoliaConfig = NetworkConfig({
    //         address = "address for sepolia should be here"
    //     });

    //     return sepoliaConfig;
    // }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //check if we have already set the pricefeed to the default address
        if (activeNetworkConfig.priceFeeds != address(0)) {
            return activeNetworkConfig;
        }
        //vm this is for deploying the mock contract to the anvil chain
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeeds: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
