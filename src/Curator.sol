// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { UUPS } from "./lib/proxy/UUPS.sol";
import { ICurator } from "./interfaces/ICurator.sol";
import { Ownable } from "./lib/utils/Ownable.sol";
import { ICuratorFactory } from "./interfaces/ICuratorFactory.sol";
import { CuratorSkeletonNFT } from "./CuratorSkeletonNFT.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";
import { CuratorStorageV1 } from "./CuratorStorageV1.sol";

contract Curator is ICurator, UUPS, Ownable, CuratorStorageV1, CuratorSkeletonNFT {
    // Public constants for curation types.
    // Allows for adding new types later easily compared to a enum.
    uint16 public constant CURATION_TYPE_GENERIC = 0;
    uint16 public constant CURATION_TYPE_NFT_CONTRACT = 1;
    uint16 public constant CURATION_TYPE_CURATION_CONTRACT = 2;
    uint16 public constant CURATION_TYPE_CONTRACT = 3;
    uint16 public constant CURATION_TYPE_NFT_ITEM = 4;
    uint16 public constant CURATION_TYPE_WALLET = 5;
    uint16 public constant CURATION_TYPE_ZORA_EDITION = 6;

    /// @notice Reference to factory contract
    ICuratorFactory private immutable curatorFactory;

    /// @notice Modifier that ensures the curator is active and not frozen
    modifier onlyActive() {
        if (isPaused && msg.sender != owner()) {
            revert CURATION_PAUSED();
        }

        if (frozenAt != 0 && frozenAt < block.timestamp) {
            revert CURATION_FROZEN();
        }

        _;
    }

    /// @notice Modifier that only allows an admin or curator of a specific entry access
    modifier onlyCuratorOrAdmin(uint256 listingId) {
        if (owner() != msg.sender || idToListing[listingId].curator != msg.sender) {
            revert ACCESS_NOT_ALLOWED();
        }

        _;
    }

    constructor(address _curatorFactory) payable initializer {
        curatorFactory = ICuratorFactory(_curatorFactory);
    }

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _curationPass,
        bool _pause,
        uint256 _curationLimit,
        address _renderer,
        bytes memory _rendererInitializer,
        Listing[] memory _initialListings
    ) external initializer {
        __Ownable_init(_owner);

        contractName = _name;
        contractSymbol = _symbol;

        curationPass = IERC721Upgradeable(_curationPass);

        _updateRenderer(IMetadataRenderer(_renderer), _rendererInitializer);

        if (_pause) {
            _setCurationPaused(_pause);
        }

        if (_curationLimit != 0) {
            _updateCurationLimit(_curationLimit);
        }

        if (_initialListings.length != 0) {
            _addListings(_initialListings, _owner);
        }
    }

    function getListing(uint256 index) external view override returns (Listing memory) {
        ownerOf(index);
        return idToListing[index];
    }

    function getListings() external view override returns (Listing[] memory activeListings) {
        unchecked {
            activeListings = new Listing[](numAdded - numRemoved);

            uint256 activeIndex;

            for (uint256 i; i < numAdded; ++i) {
                if (idToListing[i].curator == address(0)) {
                    continue;
                }

                activeListings[activeIndex] = idToListing[i];
                ++activeIndex;
            }
        }
    }

    /**
        Admin functions
     */

    function updateCurationLimit(uint256 newLimit) external onlyOwner {
        _updateCurationLimit(newLimit);
    }

    function _updateCurationLimit(uint256 newLimit) internal {
        if (curationLimit < newLimit && curationLimit != 0) {
            revert CANNOT_UPDATE_CURATION_LIMIT_DOWN();
        }
        curationLimit = newLimit;
        emit UpdatedCurationLimit(newLimit);
    }

    function freezeAt(uint256 timestamp) external onlyOwner {
        if (frozenAt != 0 && frozenAt < block.timestamp) {
            revert CURATION_FROZEN();
        }
        frozenAt = timestamp;
        emit ScheduledFreeze(frozenAt);
    }

    function updateRenderer(address _newRenderer, bytes memory _rendererInitializer) external onlyOwner {
        _updateRenderer(IMetadataRenderer(_newRenderer), _rendererInitializer);
    }

    function _updateRenderer(IMetadataRenderer _newRenderer, bytes memory _rendererInitializer) internal {
        renderer = _newRenderer;
        // If data provided, call initalize to new renderer replacement.
        if (_rendererInitializer.length > 0) {
            renderer.initializeWithData(_rendererInitializer);
        }
        emit SetRenderer(address(renderer));
    }

    function updateCurationPass(IERC721Upgradeable _curationPass) public onlyOwner {
        curationPass = _curationPass;

        emit TokenPassUpdated(msg.sender, address(_curationPass));
    }

    function setCurationPaused(bool _setPaused) public onlyOwner {
        if (isPaused == _setPaused) {
            revert CANNOT_SET_SAME_PAUSED_STATE();
        }

        _setCurationPaused(_setPaused);
    }

    function _setCurationPaused(bool _setPaused) internal {
        isPaused = _setPaused;

        emit CurationPauseUpdated(msg.sender, isPaused);
    }

    /** 
        Curator Functions
    */

    function addListings(Listing[] memory listings) external onlyActive {
        if (msg.sender != owner()) {
            if (address(curationPass).code.length == 0) {
                revert PASS_REQUIRED();
            }
            try curationPass.balanceOf(msg.sender) returns (uint256 count) {
                if (count == 0) {
                    revert PASS_REQUIRED();
                }
            } catch {
                revert PASS_REQUIRED();
            }
        }

        _addListings(listings, msg.sender);
    }

    function _addListings(Listing[] memory listings, address sender) internal {
        if (curationLimit != 0 && numAdded - numRemoved + listings.length > curationLimit) {
            revert TOO_MANY_ENTRIES();
        }

        for (uint256 i = 0; i < listings.length; ++i) {
            if (listings[i].curator != sender) {
                revert WRONG_CURATOR_FOR_LISTING(listings[i].curator, msg.sender);
            }
            if (listings[i].chainId == 0) {
                listings[i].chainId = uint16(block.chainid);
            }
            idToListing[numAdded] = listings[i];
            _mint(listings[i].curator, numAdded);
            ++numAdded;
        }
    }

    function updateSortOrders(uint256[] calldata tokenIds, int32[] calldata sortOrders) external onlyActive {
        if (tokenIds.length != sortOrders.length) {
            revert INVALID_INPUT_LENGTH();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setSortOrder(tokenIds[i], sortOrders[i]);
        }
        emit UpdatedSortOrder(tokenIds, sortOrders, msg.sender);
    }

    function _setSortOrder(uint256 listingId, int32 sortOrder) internal onlyCuratorOrAdmin(listingId) {
        idToListing[listingId].sortOrder = sortOrder;
    }

    /**
        NFT Functions
     */

    function burn(uint256 listingId) public onlyActive {
        _burnTokenWithChecks(listingId);
    }

    function burnBatch(uint256[] calldata listingIds) external onlyActive {
        unchecked {
            for (uint256 i = 0; i < listingIds.length; ++i) {
                _burnTokenWithChecks(listingIds[i]);
            }
        }
    }

    function _exists(uint256 id) internal view virtual override returns (bool) {
        return idToListing[id].curator != address(0);
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        for (uint256 i = 0; i < numAdded; ++i) {
            if (idToListing[i].curator == _owner) {
                ++balance;
            }
        }
    }

    function name() external view override returns (string memory) {
        return contractName;
    }

    function symbol() external view override returns (string memory) {
        return contractSymbol;
    }

    function totalSupply() public view override(CuratorSkeletonNFT, ICurator) returns (uint256) {
        return numAdded - numRemoved;
    }

    function ownerOf(uint256 id) public view virtual override returns (address) {
        if (!_exists(id)) {
            revert TOKEN_HAS_NO_OWNER();
        }
        return idToListing[id].curator;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return renderer.tokenURI(tokenId);
    }

    function contractURI() external view override returns (string memory) {
        return renderer.contractURI();
    }

    function _burnTokenWithChecks(uint256 listingId) internal onlyActive onlyCuratorOrAdmin(listingId) {
        Listing memory _listing = idToListing[listingId];
        // Process NFT Burn
        _burn(listingId);

        // Remove listing
        delete idToListing[listingId];
        unchecked {
            ++numRemoved;
        }

        emit ListingRemoved(msg.sender, _listing);
    }

    /**
        Contract admin functions
     */

    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {
        if (!curatorFactory.isValidUpgrade(_getImplementation(), _newImpl)) {
            revert INVALID_UPGRADE(_newImpl);
        }
    }
}
