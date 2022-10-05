// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { CuratorFactory } from "../src/CuratorFactory.sol";
import { Curator } from "../src/Curator.sol";
import { ERC1967Proxy } from "../src/lib/proxy/ERC1967Proxy.sol";
import { DefaultMetadataRenderer } from "../src/DefaultMetadataRenderer.sol";

contract DeployCore is Script {
    address internal owner;
    address internal factoryProxy;
    bool internal makeNewMetadata;

    function setUp() public {
        factoryProxy = vm.envAddress("FACTORY_PROXY");
        makeNewMetadata = vm.envBool("USE_NEW_METADATA");
    }

    function run() public {
        vm.startBroadcast();

        deployCore();

        vm.stopBroadcast();
    }

    function deployCore() internal {
        // if (makeNewMetadata) {
        //     defaultMetadataRenderer = address(new DefaultMetadataRenderer("https://renderer.zora.co/curation/"));
        // }
        // curatorImpl = address(new Curator(factoryProxy));
        // factory.upgradeTo(factoryImpl);
    }
}
