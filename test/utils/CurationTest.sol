// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import { CuratorFactory } from "../../src/CuratorFactory.sol";
import { DefaultMetadataRenderer } from "../../src/DefaultMetadataRenderer.sol";
import { Curator } from "../../src/Curator.sol";
import { ICurator } from "../../src/interfaces/ICurator.sol";

import { ERC1967Proxy } from "../../src/lib/proxy/ERC1967Proxy.sol";

import { MockERC721 } from "./mocks/MockERC721.sol";

contract CurationTestSetup is Test {
    CuratorFactory internal factory;
    Curator internal curator;

    address internal factoryImpl0;
    address internal factoryImpl;
    address internal curatorImpl;
    address internal metadataRenderer;
    address internal zora;

    MockERC721 internal mockTokenPass;

    address internal mockPassHolder;
    address internal mockCurationManager;

    ICurator.Listing[] internal mockListings;

    function setUp() public virtual {
        zora = vm.addr(0xA11CE);
        mockCurationManager = vm.addr(0xB0B);
        mockPassHolder = vm.addr(0xCAB);

        mockTokenPass = new MockERC721();
        mockTokenPass.mint(mockPassHolder, 1);

        deployCore(zora);
    }

    function deployCore(address _owner) internal {
        metadataRenderer = address(new DefaultMetadataRenderer("https://default-metadata-renderer.com/"));
        factoryImpl0 = address(new CuratorFactory(address(0), metadataRenderer));
        factory = CuratorFactory(address(new ERC1967Proxy(factoryImpl0, abi.encodeWithSelector(CuratorFactory.initialize.selector, _owner))));

        curatorImpl = address(new Curator(address(factory)));
        factoryImpl = address(new CuratorFactory(curatorImpl, metadataRenderer));

        vm.prank(_owner);
        factory.upgradeTo(factoryImpl);
    }

    function deployMockCurator() internal {
        ICurator.Listing[] memory listings = new ICurator.Listing[](0);

        address _curator = factory.deploy(
            mockCurationManager,
            "Mock Curation Contract",
            "MKCURATION",
            address(mockTokenPass),
            false,
            0,
            address(0x0),
            "",
            listings
        );

        curator = Curator(_curator);
    }

    function addBatchListings(uint256 _numListings) public {
        ICurator.Listing[] memory listingsToAdd = new ICurator.Listing[](_numListings);

        unchecked {
            for (uint256 i; i < _numListings; ++i) {
                mockListings.push();
                mockListings[i].curator = mockCurationManager;
                mockListings[i].curatedContract = address(0x123);
                mockListings[i].hasTokenId = false;
                mockListings[i].curationTargetType = curator.CURATION_TYPE_EOA_WALLET();
            }
        }

        vm.prank(mockCurationManager);
        curator.addListings(listingsToAdd);
    }
}
