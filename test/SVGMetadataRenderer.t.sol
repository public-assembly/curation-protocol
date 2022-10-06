// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import { Curator } from "../src/Curator.sol";
import { ICurator } from "../src/interfaces/ICurator.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import { CurationTestSetup } from "./utils/CurationTest.sol";
import { MockERC721 } from "./utils/mocks/MockERC721.sol";

import {console2} from "forge-std/console2.sol";

contract SVGMetadataRendererTest is CurationTestSetup {
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

    function test_ListingCuratedNFTShow() public {
        deployMockCurator();

        MockERC721 testNFT = new MockERC721();
        testNFT.mint(address(this));
        testNFT.mint(address(this));

        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
        listings[0].curatedAddress = address(testNFT);
        listings[0].hasTokenId = true;
        listings[0].selectedTokenId = 1;
        listings[0].curationTargetType = curator.CURATION_TYPE_NFT_ITEM();
        listings[0].curator = mockCurationManager;

        vm.prank(mockCurationManager);
        curator.addListings(listings);

        console2.log(curator.contractURI());
        string[] memory args = new string[](4);
        args[0] = 'node';
        args[1] = './utils/decode-baseuri.js';
        args[2] = curator.contractURI();
        args[3] = './svg-out/svg-test-out.svg';


        console2.log(string(vm.ffi(args)));
    }

    function test_AddListingsIndexed() public {

        deployMockCurator();

        MockERC721 testNFT = new MockERC721();
        testNFT.mint(address(this));
        testNFT.mint(address(this)); 

        ICurator.Listing[] memory listings = new ICurator.Listing[](1);
        listings[0].curatedAddress = address(testNFT);
        listings[0].hasTokenId = true;
        listings[0].selectedTokenId = 1;
        listings[0].curationTargetType = curator.CURATION_TYPE_NFT_ITEM();
        listings[0].curator = mockCurationManager;

        vm.prank(mockCurationManager);
        curator.addListings(listings);

        string[] memory args = new string[](4);
        args[0] = 'node';
        args[1] = './utils/decode-baseuri.js';
        args[2] = curator.tokenURI(0);
        args[3] = './svg-out/svg-test-out-token-1.svg';
        console2.log(string(vm.ffi(args)));
    }

}
