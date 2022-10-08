// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IMetadataRenderer } from "../interfaces/IMetadataRenderer.sol";
import { IOwnable } from "../lib/interfaces/IOwnable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @notice This is the default metadata renderer for string concatenated rendering.
 * @author iain@zora.co
 */
contract DefaultMetadataRenderer is IMetadataRenderer {
    string defaultBaseURI;
    mapping(address => string) overrideBaseURI;

    error TARGET_NOT_OWNED();

    event UpdatedBaseURI(address target, string newURI);

    constructor(string memory _defaultBaseURI) {
        defaultBaseURI = _defaultBaseURI;
        emit UpdatedBaseURI(address(0x0), _defaultBaseURI);
    }

    function setBaseURI(address target, string memory newBaseURI) external {
        if (IOwnable(target).owner() != msg.sender) {
            revert TARGET_NOT_OWNED();
        }
        overrideBaseURI[target] = newBaseURI;
        emit UpdatedBaseURI(target, newBaseURI);
    }

    function initializeWithData(bytes memory initData) external {
        if (initData.length > 0) {
            string memory newBaseURI = abi.decode(initData, (string));
            overrideBaseURI[msg.sender] = newBaseURI;
        }
    }

    function contractURI() external view override returns (string memory) {
        return string(abi.encodePacked(_getBaseURI(), Strings.toHexString(msg.sender), "/contract.json"));
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(_getBaseURI(), Strings.toHexString(msg.sender), "/", Strings.toString(tokenId), ".json"));
    }

    function _getBaseURI() internal view returns (string memory) {
        if (bytes(overrideBaseURI[msg.sender]).length > 0) {
            return overrideBaseURI[msg.sender];
        }
        return defaultBaseURI;
    }
}
