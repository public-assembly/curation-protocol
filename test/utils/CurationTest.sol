// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import { CuratorFactory } from "../../src/CuratorFactory.sol";
import { SVGMetadataRenderer } from "../../src/renderer/SVGMetadataRenderer.sol";
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

    MockERC721 internal mockCurationPass;

    address internal mockPassHolder;
    address internal mockCurationManager;

    ICurator.Listing[] internal mockListings;

    function setUp() public virtual {
        zora = vm.addr(0xA11CE);
        mockCurationManager = vm.addr(0xB0B);
        mockPassHolder = vm.addr(0xCAB);

        mockCurationPass = new MockERC721();
        mockCurationPass.mint(mockPassHolder);

        deployCore(zora);
    }

    function deployCore(address _owner) internal {
        metadataRenderer = address(new SVGMetadataRenderer());
        factoryImpl0 = address(new CuratorFactory(address(0)));
        factory = CuratorFactory(
            address(new ERC1967Proxy(factoryImpl0, abi.encodeWithSelector(CuratorFactory.initialize.selector, _owner, metadataRenderer)))
        );

        curatorImpl = address(new Curator(address(factory)));
        factoryImpl = address(new CuratorFactory(curatorImpl));

        vm.prank(_owner);
        factory.upgradeTo(factoryImpl);
    }

    function deployMockCurator() internal {
        ICurator.Listing[] memory listings = new ICurator.Listing[](0);

        address _curator = factory.deploy(
            mockCurationManager,
            "Mock Curation Contract",
            "MKCURATION",
            address(mockCurationPass),
            false,
            0,
            address(0x0),
            "",
            listings
        );

        curator = Curator(_curator);
    }

    function addBatchListings(uint256 _numListings, address minter) public {
        ICurator.Listing[] memory listingsToAdd = new ICurator.Listing[](_numListings);

        unchecked {
            for (uint256 i; i < _numListings; ++i) {
                mockListings.push();
                mockListings[i].curator = minter;
                mockListings[i].curatedAddress = address(0x123);
                mockListings[i].hasTokenId = false;
                mockListings[i].curationTargetType = curator.CURATION_TYPE_WALLET();
            }
        }

        mockCurationPass.mint(minter);
        vm.prank(minter);
        curator.addListings(mockListings);
    }
}
