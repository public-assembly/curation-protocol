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

    function test_InitalListings() public {
        deployMockCurator();

    }

    function test_AddCuratorList() public {
        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
        listings[0].curator = mockCurationManager;

        ICurator _curator = ICurator(factory.deploy(
            mockCurationManager,
            "Mock Curation Contract",
            "MKCURATION",
            address(mockCurationPass),
            false,
            0,
            address(0x0),
            "",
            listings
        ));
        
        assertEq(_curator.totalSupply(), 1);
    }

    function test_AddListing() public {
        deployMockCurator();

        vm.startPrank(mockPassHolder);
        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
        listings[0].curator = mockPassHolder;
        listings[0].curatedAddress = address(0x123);
        listings[0].curationTargetType = curator.CURATION_TYPE_GENERIC();
        curator.addListings(listings);
    }

    function testRevert_CannotAddListingWithoutPass() public {
        deployMockCurator();

        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
        listings[0].curatedAddress = address(0x123);
        listings[0].curationTargetType = curator.CURATION_TYPE_GENERIC();

        vm.expectRevert(abi.encodeWithSignature("PASS_REQUIRED()"));
        curator.addListings(listings);
    }

    function test_OwnerAddListing() public {
        deployMockCurator();

        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
        listings[0].curatedAddress = address(0x123);
        listings[0].curationTargetType = curator.CURATION_TYPE_GENERIC();
        listings[0].curator = mockCurationManager;

        vm.prank(mockCurationManager);
        curator.addListings(listings);
    }

    function test_NFTMinting() public {
        deployMockCurator();

        ICurator.Listing[] memory listingsToAdd = new ICurator.Listing[](1);
        listingsToAdd[0].curator = mockCurationManager;
        listingsToAdd[0].curatedAddress = address(0x123);
        listingsToAdd[0].hasTokenId = false;
        listingsToAdd[0].curationTargetType = curator.CURATION_TYPE_WALLET();

        mockCurationPass.mint(mockCurationManager);
        vm.expectEmit(true, true, true, true);
        mockCurationPass.emitTransfer(address(0x0), mockCurationManager, 0);
        vm.prank(mockCurationManager);
        curator.addListings(listingsToAdd);
    }

    function test_AddListings() public {
        deployMockCurator();

        addBatchListings(5, mockCurationManager);

        curator.getListings();
    }

    function test_RemoveListings() public {
        deployMockCurator();

        addBatchListings(5, mockCurationManager);

        vm.startPrank(mockCurationManager);

        vm.expectEmit(true, true, true, true);
        mockCurationPass.emitTransfer(mockCurationManager, address(0x0), 2);
        curator.burn(2);

        vm.expectEmit(true, true, true, true);
        mockCurationPass.emitTransfer(mockCurationManager, address(0x0), 4);
        curator.burn(4);
        vm.stopPrank();

        curator.getListings();
    }

    function test_RemoveListingsByCurator() public {
        deployMockCurator();

        address randomLister = address(0x312412);
        addBatchListings(5, randomLister);

        vm.startPrank(randomLister);

        vm.expectEmit(true, true, true, true);
        mockCurationPass.emitTransfer(randomLister, address(0x0), 2);
        curator.burn(2);

        vm.expectEmit(true, true, true, true);
        mockCurationPass.emitTransfer(randomLister, address(0x0), 4);
        curator.burn(4);
        vm.stopPrank();

        curator.getListings();
    }

        function test_RemoveListingsByAdmin() public {
        deployMockCurator();

        address randomLister = address(0x312412);
        addBatchListings(5, randomLister);

        vm.startPrank(mockCurationManager);

        vm.expectEmit(true, true, true, true);
        mockCurationPass.emitTransfer(randomLister, address(0x0), 2);
        curator.burn(2);

        vm.expectEmit(true, true, true, true);
        mockCurationPass.emitTransfer(randomLister, address(0x0), 4);
        curator.burn(4);
        vm.stopPrank();

        curator.getListings();
    }

    function test_RemoveListingFailIfPaused() public {
        deployMockCurator();

        address randomLister = address(0x312412);
        addBatchListings(5, randomLister);

        vm.prank(mockCurationManager);
        curator.setCurationPaused(true);
        vm.startPrank(randomLister);
        vm.expectRevert(ICurator.CURATION_PAUSED.selector);
        curator.burn(2);
    }

    function test_RemoveListingsFailIfPaused() public {
        deployMockCurator();

        address randomLister = address(0x312412);
        addBatchListings(5, randomLister);

        vm.prank(mockCurationManager);
        curator.setCurationPaused(true);
        vm.startPrank(randomLister);
        uint256[] memory burnBatchIds = new uint256[](2);
        burnBatchIds[0] = 1;
        burnBatchIds[0] = 2;
        vm.expectRevert(ICurator.CURATION_PAUSED.selector);
        curator.removeListings(burnBatchIds);
    }

    function test_RemoveListingsFailIfFrozen() public {
        deployMockCurator();

        addBatchListings(5, mockCurationManager);

        vm.startPrank(mockCurationManager);
        curator.freezeAt(1);
        vm.warp(10);
        uint256[] memory burnBatchIds = new uint256[](2);
        burnBatchIds[0] = 1;
        burnBatchIds[0] = 2;
        vm.expectRevert(ICurator.CURATION_FROZEN.selector);
        curator.removeListings(burnBatchIds);
    }
}
