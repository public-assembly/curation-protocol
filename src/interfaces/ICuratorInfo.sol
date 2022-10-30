// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IAccessControlRegistry } from "./interfaces/IAccessControlRegistry.sol";

interface ICuratorInfo {
    function name() external view returns (string memory);

    function accessControl() external view returns (IAccessControlRegistry);

    // function curationPass() external view returns (IERC721Metadata);

    function owner() external view returns (address);
}
