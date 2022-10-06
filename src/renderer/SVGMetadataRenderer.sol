// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IMetadataRenderer } from "../interfaces/IMetadataRenderer.sol";
import { ICuratorInfo, IERC721Metadata } from "../interfaces/ICuratorInfo.sol";
import { IZoraDrop } from "../interfaces/IZoraDrop.sol";
import { ICurator } from "../interfaces/ICurator.sol";

import { MetadataBuilder } from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import { MetadataJSONKeys } from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";

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

    function _getTotalSupplySaturation(address nft) internal view returns (uint16) {
        try ICurator(nft).totalSupply() returns (uint256 supply) {
            if (supply > 10000) {
                return 100;
            }
            if (supply > 1000) {
                return 75;
            }
            if (supply > 100) {
                return 50;
            }
        } catch {}
        return 10;
    }

    function _getEditionPercentMintedSaturationSquareDensity(address nft) internal view returns (uint16 saturation, uint256 density) {
        try IZoraDrop(nft).saleDetails() returns (IZoraDrop.SaleDetails memory saleDetails) {
            uint256 bpsMinted = (saleDetails.totalMinted * 10000) / saleDetails.maxSupply;
            if (bpsMinted > 7500) {
                return (100, 20);
            }
            if (bpsMinted > 5000) {
                return (75, 50);
            }
            if (bpsMinted > 2500) {
                return (50, 70);
            }
        } catch {}
        return (10, 100);
    }

    function generateGridForAddress(
        address target,
        RenderingType types,
        address owner
    ) public view returns (string memory) {
        uint16 saturationOuter = 25;

        uint256 squares = 0;
        uint256 freqDiv = 23;
        uint256 hue = 0;

        if (types == RenderingType.NFT) {
            squares = 4;
            freqDiv = 23;
            hue = 168;
            saturationOuter = _getTotalSupplySaturation(owner);
        }

        if (types == RenderingType.EDITION) {
            (saturationOuter, freqDiv) = _getEditionPercentMintedSaturationSquareDensity(owner);
            hue = 317;
        }

        if (types == RenderingType.ADDRESS) {
            hue = 317;
        }

        if (types == RenderingType.CURATION) {
            hue = 120;
        }

        string memory svgInner = string.concat(
            CurationMetadataBuilder._makeSquare({ size: 720, x: 0, y: 0, color: makeHSL({ h: 317, s: saturationOuter, l: 30 }) }),
            CurationMetadataBuilder._makeSquare({ size: 600, x: 30, y: 98, color: makeHSL({ h: 317, s: saturationOuter, l: 50 }) }),
            CurationMetadataBuilder._makeSquare({ size: 480, x: 60, y: 180, color: makeHSL({ h: 317, s: saturationOuter, l: 70 }) }),
            CurationMetadataBuilder._makeSquare({ size: 60, x: 90, y: 270, color: makeHSL({ h: 317, s: saturationOuter, l: 70 }) })
        );

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

        return MetadataBuilder.generateEncodedSVG("0 0 720 720", "720", "720", svgInner);
    }

    function contractURI() external view override returns (string memory) {
        ICuratorInfo curation = ICuratorInfo(msg.sender);
        MetadataBuilder.JSONItem[] items = new MetadataBuilder.JSONItem[](3);

        string memory curationName = "Untitled NFT";

        try curation.curationPass().name() returns (string memory result) {
            curationName = result;
        } catch {}

        items[0].name = MetadataJSONKeys.keyName;
        items[0].value = string.concat("Curator: ", curation.name());
        items[0].quote = true;

        items[1].name = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
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
        items[1].quote = true;
        items[2].name = MetadataJSONKeys.keyImage;
        items[2].quote = true;
        items[2].value = generateGridForAddress(msg.sender, RenderingType.CURATION, address(0x0));

        return CurationMetadataBuilder.generateEncodedJSON(items);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        ICurator curator = ICurator(msg.sender);

        MetadataBuilder.JSONItem[] items = new MetadataBuilder.JSONItem[](3);
        MetadataBuilder.JSONItem[] properties = new MetadataBuilder.JSONItem[](0);
        ICurator.Listing memory listing = curator.getListing(tokenId);

        string memory curationName = "Untitled NFT";
        RenderingType renderingType = RenderingType.ADDRESS;
        if (listing.curationTargetType == curator.CURATION_TYPE_NFT_ITEM()) {
            renderingType = RenderingType.NFT;
            properties = new MetadataBuilder.JSONItem[](3);
            properites[0].name = "type";
            properties[0].value = "NFT Item";
            properties[1].name = "contract";
            properties[1].value = Strings.toHexString(listing.curatedAddress);
            
        }
        if (listing.curationTargetType == curator.CURATION_TYPE_NFT_CONTRACT()) {
            renderingType = RenderingType.CONTRACT;
        }
        if (listing.curationTargetType == curator.CURATION_TYPE_ZORA_EDITION()) {
            renderingType = RenderingType.EDITION;
        }
        if (listing.curationTargetType == curator.CURATION_TYPE_CURATION_CONTRACT()) {
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
        values[2] = generateGridForAddress(msg.sender, renderingType, listing.curatedAddress);

        return CurationMetadataBuilder.generateJSON(keys, values);
    }
}
