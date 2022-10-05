// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { CuratorFactory } from "../src/CuratorFactory.sol";
import { Curator } from "../src/Curator.sol";
import { ERC1967Proxy } from "../src/lib/proxy/ERC1967Proxy.sol";
import { SVGMetadataRenderer } from "../src/renderer/SVGMetadataRenderer.sol";

import { console2 } from "forge-std/console2.sol";

contract DeployCore is Script {
    address internal owner;
    address internal factoryProxy;
    address internal existingMetadata;

    function setUp() public {
        factoryProxy = vm.envAddress("FACTORY_PROXY");
        // owner = vm.envAddress("OWNER");
        existingMetadata = vm.envAddress("EXISTING_METADATA");
    }

    function run() public {
        vm.startBroadcast();

        deployCore();

        vm.stopBroadcast();
    }

    function deployCore() internal {
        if (existingMetadata == address(0x0)) {
            existingMetadata = address(new SVGMetadataRenderer());
        }
        CuratorFactory factory = CuratorFactory(factoryProxy);
        address lastCuratorImpl = address(factory.curatorImpl());
        address curatorImpl = address(new Curator(factoryProxy));
        address factoryImpl = address(new CuratorFactory(curatorImpl));
        factory.upgradeTo(factoryImpl);
        // factory.addValidUpgradePath(lastCuratorImpl, curatorImpl);
        console2.log("New curator impl: ");
        console2.log(curatorImpl);
        console2.log("New factory impl: ");
        console2.log(factoryImpl);
    }
}
