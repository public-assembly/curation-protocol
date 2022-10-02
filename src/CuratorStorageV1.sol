// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ICurator } from "./interfaces/ICurator.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";


abstract contract CuratorStorageV1 is ICurator {
    string internal contractName;

    string internal contractSymbol;

    IERC721Upgradeable public curationPass;

    /// Stores virtual mapping array length parameters
    /// @notice Array total size (total size)
    uint40 public numAdded;
    /// @notice Array active size = numAdded - numRemoved
    /// @dev Blank entries are retained within array
    uint40 public numRemoved;
    /// @notice If curation is paused by the owner
    bool public isPaused;
    /// @notice timestamp that the curation is frozen at (if never, frozen = 0)
    uint256 public frozenAt;
    /// @notice Limit of # of items that can be curated
    uint256 public curationLimit;
    /// @notice Address of the NFT Metadata renderer contract
    IMetadataRenderer public renderer;
    /// @notice Listing id => Listing struct mapping, listing IDs are 0 => upwards
    /// @dev Can contain blank entries (not garbage compacted!)
    mapping(uint256 => Listing) public idToListing;
}
