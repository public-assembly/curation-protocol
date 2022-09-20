// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import { CuratorFactory } from "../src/CuratorFactory.sol";
import { Curator } from "../src/Curator.sol";
import { ERC1967Proxy } from "../src/lib/proxy/ERC1967Proxy.sol";

contract DeployCore is Script {
    address internal owner;

    address internal factoryImpl0;
    address internal factoryImpl;
    address internal curatorImpl;

    CuratorFactory internal factory;

    function setUp() public {
        owner = vm.envAddress("OWNER");
    }

    function run() public {
        vm.startBroadcast();

        deployCore();

        vm.stopBroadcast();
    }

    function deployCore() internal {
        factoryImpl0 = address(new CuratorFactory(address(0)));
        factory = CuratorFactory(address(new ERC1967Proxy(factoryImpl0, abi.encodeWithSignature("initialize(address)", owner))));

        curatorImpl = address(new Curator(address(factory)));
        factoryImpl = address(new CuratorFactory(curatorImpl));

        factory.upgradeTo(factoryImpl);
    }
}
