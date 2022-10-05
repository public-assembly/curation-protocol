// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IMetadataRenderer } from "../interfaces/IMetadataRenderer.sol";
import { ICuratorInfo, IERC721Metadata } from "../interfaces/ICuratorInfo.sol";
import { ICurator } from "../interfaces/ICurator.sol";
import { CurationMetadataBuilder } from "./CurationMetadataBuilder.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract SVGMetadataRenderer is IMetadataRenderer {
    function initializeWithData(bytes memory initData) public {}

    enum RenderingType {
        CURATION,
        NFT,
        EDITION,
        CONTRACT,
        ADDRESS
    }

    function makeHSL(
        uint16 h,
        uint16 s,
        uint16 l
    ) internal pure returns (string memory) {
        return string.concat("hsl(", Strings.toString(h), ",", Strings.toString(s), "%,", Strings.toString(l), "%)");
    }

    function generateGridForAddress(
        address target,
        RenderingType types,
        address owner
    ) public pure returns (string memory) {
        uint16 saturationOuter = 25;

        string memory svgInner = string.concat(
            CurationMetadataBuilder._makeSquare({ size: 720, x: 0, y: 0, color: makeHSL({ h: 317, s: saturationOuter, l: 30 }) }),
            CurationMetadataBuilder._makeSquare({ size: 600, x: 30, y: 98, color: makeHSL({ h: 317, s: saturationOuter, l: 50 }) }),
            CurationMetadataBuilder._makeSquare({ size: 480, x: 60, y: 180, color: makeHSL({ h: 317, s: saturationOuter, l: 70 }) }),
            CurationMetadataBuilder._makeSquare({ size: 60, x: 90, y: 270, color: makeHSL({ h: 317, s: saturationOuter, l: 70 }) })
        );

        uint256 squares = 0;
        uint256 freqDiv = 23;

        if (types == RenderingType.NFT) {
            squares = 4;
            freqDiv = 23;
        }

        if (types == RenderingType.EDITION) {
            squares = 6;
            freqDiv = 10;
        }

        uint256 addr = uint160(uint160(owner));
        for (uint256 i = 0; i < squares * squares; i++) {
            addr /= freqDiv;
            if (addr % 3 == 0) {
                uint256 size = 720 / squares;
                svgInner = string.concat(
                    svgInner,
                    CurationMetadataBuilder._makeSquare({ size: size, x: (i % squares) * size, y: (i / squares) * size, color: "rgba(0, 0, 0, 0.4)" })
                );
            }
        }

        return
            CurationMetadataBuilder.encodeURI(
                "application/svg+xml",
                string.concat('<svg viewBox="0 0 720 720" xmlns="http://www.w3.org/2000/svg" width="720" height="720">', svgInner, "</svg>")
            );
    }

    function contractURI() external view override returns (string memory) {
        ICuratorInfo curation = ICuratorInfo(msg.sender);
        string[] memory keys = new string[](3);
        string[] memory values = new string[](3);

        string memory curationName = "Untitled NFT";

        try curation.curationPass().name() returns (string memory result) {
            curationName = result;
        } catch {}

        keys[0] = CurationMetadataBuilder.key_name;
        values[0] = string.concat("Curator: ", curation.name());
        keys[1] = CurationMetadataBuilder.key_description;
        values[1] = string.concat(
            "This is a curation NFT owned by ",
            Strings.toHexString(curation.owner()),
            "\\n\\nThe NFTs in this collection mark curators curating this collection."
            "The curation pass for this NFT is ",
            curationName,
            "\\n\\nThese NFTs only mark curations and are non-transferrable."
            "\\n\\nView or manage this curation at: "
            "https://public---assembly.com/",
            Strings.toHexString(msg.sender),
            "\\n\\nA project of public assembly."
        );
        keys[2] = CurationMetadataBuilder.key_image;
        values[2] = generateGridForAddress(msg.sender, RenderingType.CURATION, address(0x0));

        return CurationMetadataBuilder.generateJSON(keys, values);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        ICurator curator = ICurator(msg.sender);
        string[] memory keys = new string[](3);
        string[] memory values = new string[](3);

        ICurator.Listing memory listing = curator.getListing(tokenId);

        string memory curationName = "Untitled NFT";
        RenderingType renderingType = RenderingType.CONTRACT;
        if (listing.curationTargetType == curator.CURATION_TYPE_NFT_ITEM()) {
            renderingType = RenderingType.NFT;
        }
        if (listing.curationTargetType == curator.CURATION_TYPE_NFT_CONTRACT()) {
            renderingType = RenderingType.CONTRACT;
        }

        if (listing.curationTargetType == curator.CURATION_TYPE_NFT_CONTRACT() || listing.curationTargetType == curator.CURATION_TYPE_NFT_ITEM()) {
            if (listing.curatedAddress.code.length > 0) {
                try ICuratorInfo(listing.curatedAddress).name() returns (string memory result) {
                    curationName = result;
                } catch {}
            }
        }

        keys[0] = CurationMetadataBuilder.key_name;
        values[0] = string.concat("Curation #", Strings.toString(tokenId), ": ", curationName);
        keys[1] = CurationMetadataBuilder.key_description;
        values[1] = string.concat(
            "This is an item curated by ",
            Strings.toHexString(listing.curator),
            "\\n\\nTo remove this curation, burn the NFT. "
            "\\n\\nThis NFT is non-transferrable. "
            "\\n\\nA project of public assembly. "
        );
        keys[2] = CurationMetadataBuilder.key_image;
        // console2.log(uint16(renderingType));
        values[2] = generateGridForAddress(msg.sender, renderingType, listing.curatedAddress);

        return CurationMetadataBuilder.generateJSON(keys, values);
    }
}
