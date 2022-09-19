// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import { CuratorFactory } from "../../src/CuratorFactory.sol";
import { Curator } from "../../src/Curator.sol";

import { ERC1967Proxy } from "../../src/lib/proxy/ERC1967Proxy.sol";

import { MockERC721 } from "./mocks/MockERC721.sol";

contract CurationTestSetup is Test {
    CuratorFactory internal factory;
    Curator internal curator;

    address internal factoryImpl0;
    address internal factoryImpl;
    address internal curatorImpl;
    address internal zora;

    MockERC721 internal mockTokenPass;

    address internal mockPassHolder;
    address internal mockCurationManager;
    address[] internal mockListings;

    function setUp() public virtual {
        zora = vm.addr(0xA11CE);
        mockCurationManager = vm.addr(0xB0B);
        mockPassHolder = vm.addr(0xCAB);

        mockTokenPass = new MockERC721();
        mockTokenPass.mint(mockPassHolder, 1);

        deployCore(zora);
    }

    function deployCore(address _owner) internal {
        factoryImpl0 = address(new CuratorFactory(address(0)));
        factory = CuratorFactory(address(new ERC1967Proxy(factoryImpl0, abi.encodeWithSignature("initialize(address)", _owner))));

        curatorImpl = address(new Curator(address(factory)));
        factoryImpl = address(new CuratorFactory(curatorImpl));

        vm.prank(_owner);
        factory.upgradeTo(factoryImpl);
    }

    function deployMockCurator() internal {
        address _curator = factory.deploy(mockCurationManager, "Mock Curation Contract", address(mockTokenPass), false);

        curator = Curator(_curator);
    }

    function createListings(uint256 _numListings) internal {
        mockListings = new address[](_numListings);

        unchecked {
            for (uint256 i; i < _numListings; ++i) mockListings[i] = vm.addr(i + 1);
        }
    }

    function addBatchListings(uint256 _numListings) public {
        createListings(_numListings);

        for (uint256 i; i < _numListings; ++i) {
            vm.prank(mockCurationManager);
            curator.ownerAddListing(mockListings[i]);
        }
    }
}
