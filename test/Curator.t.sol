// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import { Curator } from "../src/Curator.sol";
import { ICurator } from "../src/interfaces/ICurator.sol";

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

        vm.prank(mockPassHolder);
        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
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

        vm.prank(mockCurationManager);
        curator.addListings(listings);
    }

    function test_AddListings() public {
        deployMockCurator();

        addBatchListings(5);

        curator.getListings();
    }

    function test_RemoveListings() public {
        deployMockCurator();

        addBatchListings(5);

        vm.prank(mockCurationManager);
        curator.burn(2);

        vm.prank(mockCurationManager);
        curator.burn(4);

        curator.getListings();
    }
}
