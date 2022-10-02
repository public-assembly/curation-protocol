// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import { Curator } from "../src/Curator.sol";
import { ICurator } from "../src/interfaces/ICurator.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import { CurationTestSetup } from "./utils/CurationTest.sol";
import { MockERC721 } from "./utils/mocks/MockERC721.sol";

contract CuratorTest is CurationTestSetup {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_DeployMockCurator() public {
        deployMockCurator();

        assertEq(curator.owner(), mockCurationManager);
        assertEq(curator.name(), "Mock Curation Contract");
    }

    function test_AddListing() public {
        deployMockCurator();

        vm.startPrank(mockPassHolder);
        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
        listings[0].curator = mockPassHolder;
        listings[0].curatedContract = address(0x123);
        listings[0].curationTargetType = curator.CURATION_TYPE_GENERIC();
        curator.addListings(listings);
    }

    function testRevert_CannotAddListingWithoutPass() public {
        deployMockCurator();

        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
        listings[0].curatedContract = address(0x123);
        listings[0].curationTargetType = curator.CURATION_TYPE_GENERIC();

        vm.expectRevert(abi.encodeWithSignature("PASS_REQUIRED()"));
        curator.addListings(listings);
    }

    function test_OwnerAddListing() public {
        deployMockCurator();

        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
        listings[0].curatedContract = address(0x123);
        listings[0].curationTargetType = curator.CURATION_TYPE_GENERIC();
        listings[0].curator = mockCurationManager;

        vm.prank(mockCurationManager);
        curator.addListings(listings);
    }

    function test_NFTMinting() public {
        deployMockCurator();

        ICurator.Listing[] memory listingsToAdd = new ICurator.Listing[](1);
        listingsToAdd[0].curator = mockCurationManager;
        listingsToAdd[0].curatedContract = address(0x123);
        listingsToAdd[0].hasTokenId = false;
        listingsToAdd[0].curationTargetType = curator.CURATION_TYPE_EOA_WALLET();

        mockTokenPass.mint(mockCurationManager);
        vm.expectEmit(true, true, true, true);
        mockTokenPass.emitTransfer(address(0x0), mockCurationManager, 0);
        vm.prank(mockCurationManager);
        curator.addListings(listingsToAdd);
    }

    function test_AddListings() public {
        deployMockCurator();

        addBatchListings(5);

        curator.getListings();
    }

    function test_RemoveListings() public {
        deployMockCurator();

        addBatchListings(5);

        vm.startPrank(mockCurationManager);
        curator.burn(2);
        curator.burn(4);
        vm.stopPrank();

        curator.getListings();
    }
}
