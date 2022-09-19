// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import { Curator } from "../src/Curator.sol";

import { CurationTestSetup } from "./utils/CurationTest.sol";
import { MockERC721 } from "./utils/mocks/MockERC721.sol";

contract CuratorTest is CurationTestSetup {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_DeployMockCurator() public {
        deployMockCurator();

        assertEq(curator.owner(), mockCurationManager);
        assertEq(curator.title(), "Mock Curation Contract");
    }

    function test_AddListing() public {
        deployMockCurator();

        vm.prank(mockPassHolder);
        curator.addListing(address(1));
    }

    function testRevert_CannotAddListingWithoutPass() public {
        deployMockCurator();

        vm.expectRevert(abi.encodeWithSignature("PASS_REQUIRED()"));
        curator.addListing(address(1));
    }

    function test_OwnerAddListing() public {
        deployMockCurator();

        vm.prank(mockCurationManager);
        curator.ownerAddListing(address(1));
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
        curator.ownerRemoveListing(mockListings[2]);

        vm.prank(mockCurationManager);
        curator.ownerRemoveListing(mockListings[4]);

        curator.getListings();
    }
}
