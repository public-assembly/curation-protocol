// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library CurationMetadataBuilder {
    bytes32 constant key_name = "name";
    bytes32 constant key_description = "description";
    bytes32 constant key_image = "image";

    function encodeURI(string memory uriType, string memory result) internal pure returns (string memory) {
        return string.concat("data:", uriType, ";base64,", string(Base64.encode(bytes(result))));
    }

    function generateJSON(bytes32[] memory keys, string[] memory values) internal pure returns (string memory) {
        string memory result;
        for (uint256 i = 0; i < keys.length; i++) {
            result = string(abi.encodePacked(result, '"', keys[i], '": "', values[i], '"'));
        }
        return encodeURI("application/json", result);
    }

    function map(
        uint256 x,
        uint256 xMax,
        uint256 xMin,
        uint256 y,
        uint256 yMin,
        uint256 yMax
    ) internal pure returns (uint256) {
        return ((x - xMin) * (yMax - yMin)) / (xMax - xMin) + xMin;
    }

    function _makeSquare(
        uint256 size,
        uint256 x,
        uint256 y,
        string memory color
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<rect x="',
                Strings.toString(x),
                '" y="',
                Strings.toString(y),
                '" width="',
                Strings.toString(size),
                '" height="',
                Strings.toString(size),
                '" style="fill: ',
                color,
                '" />'
            );
    }
}