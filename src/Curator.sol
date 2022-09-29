// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { UUPS } from "./lib/proxy/UUPS.sol";
import { Ownable } from "./lib/utils/Ownable.sol";
import { ICuratorFactory } from "./CuratorFactory.sol";
import { CuratorSkeletonNFT } from "./CuratorSkeletonNFT.sol";


interface ICurator {
    struct Listing {
        address curatedContract;
        uint96 tokenId;
        address curator;
        uint16 curationTargetType;
        int32 sortOrder;
        bool hasTokenId;
    }

    event ListingAdded(address indexed curator, Listing listing);

    event ListingRemoved(address indexed curator, Listing listing);

    event TitleUpdated(address indexed owner, string title);

    event TokenPassUpdated(address indexed owner, address tokenPass);

    event CurationPaused(address indexed owner);

    event CurationResumed(address indexed owner);

    event UpdatedCurationLimit(uint256 newLimit);

    event UpdatedSortOrder(uint256[], int32[], address);

    event ScheduledFreeze(uint256);

    event NameUpdated(string newName);

    error PASS_REQUIRED();

    error ONLY_CURATOR();

    error CURATION_PAUSED();

    error CURATION_FROZEN();

    error LISTING_EXISTS();

    error HAS_TOO_MANY_ITEMS();

    error TOO_MANY_ENTRIES();

    error NOT_ALLOWED();

    error NO_OWNER();

    error INVALID_INPUT_LENGTH();

    error CANNOT_UPDATE_CURATION_LIMIT_DOWN();

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _tokenPass,
        bool _pause
    ) external;
}

abstract contract CuratorStorageV1 is ICurator {
    string public contractName;
    string public contractSymbol;

    IERC721Upgradeable public curationPass;

    uint40 internal numAdded;

    uint40 internal numRemoved;

    bool internal isPaused;

    uint256 internal frozenAt;

    uint256 internal curationLimit;
    
    /// @dev Listing id => Listing address
    mapping(uint256 => Listing) internal idToListing;
}

contract Curator is UUPS, Ownable, CuratorStorageV1, CuratorSkeletonNFT {

    uint256 constant TYPE_GENERIC = 0;
    uint256 constant TYPE_NFT_CONTRACT = 1;
    uint256 constant TYPE_CURATION_CONTRACT = 2;
    uint256 constant CURATION_CONTRACT = 3;
    uint256 constant NFT_ITEM = 4;
    uint256 constant EOA_WALLET = 5;

    ICuratorFactory private immutable curatorFactory;

    modifier onlyActive {
        if (isPaused && msg.sender != owner()) {
            revert CURATION_PAUSED();
        }

        if (frozenAt != 0 && frozenAt < block.timestamp) {
            revert CURATION_FROZEN();
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
        uint256 _curationLimit
    ) external initializer {
        __Ownable_init(_owner);

        contractName = _name;
        contractSymbol = _symbol;

        curationPass = IERC721Upgradeable(_curationPass);

        if (_pause) {
            _setCurationPaused(_pause);
        }

        if (_curationLimit != 0) {
            updateCurationLimit(_curationLimit);
        }

    }

    function getListings() external view returns (Listing[] memory activeListings) {
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

    function addListings(
        Listing[] calldata listings
    ) external onlyActive {
        if (curationPass.balanceOf(msg.sender) == 0) {
            if (msg.sender != owner()) {
                revert PASS_REQUIRED();
            }
        }

        if (curationLimit != 0 && numAdded - numRemoved + listings.length > curationLimit) {
            revert HAS_TOO_MANY_ITEMS();
        }

        for (uint256 i = 0; i < listings.length; ++i) {
            idToListing[numAdded] = listings[i]; 
            idToListing[numAdded].curator = msg.sender;
            ++numAdded;
        }
        if (listings.length > type(uint40).max) {
            revert TOO_MANY_ENTRIES();
        }
        numAdded += uint40(listings.length);
    }

    function updateCurationLimit(uint256 newLimit) external {
        if (curationLimit < newLimit && curationLimit != 0) {
            revert CANNOT_UPDATE_CURATION_LIMIT_DOWN();
        }
        curationLimit = newLimit;
        emit UpdatedCurationLimit(newLimit);
    }

    function updateSortOrders(uint256[] calldata tokenIds, int32[] calldata sortOrders) external onlyActive {
        if (tokenIds.length != sortOrders.length) {
            revert INVALID_INPUT_LENGTH();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (msg.sender != owner() && msg.sender != idToListing[tokenIds[i]].curator) {
                revert NOT_ALLOWED();
            }
            idToListing[tokenIds[i]].sortOrder = sortOrders[i];
        }
        emit UpdatedSortOrder(tokenIds, sortOrders, msg.sender);
    }

    function freezeAt(uint256 timestamp) external onlyOwner {
        if (frozenAt != 0 && frozenAt < block.timestamp) {
            revert CURATION_FROZEN();
        }
        frozenAt = timestamp;
        emit ScheduledFreeze(frozenAt);
    }

    function burn(uint256 listingId) public onlyActive { 
        _burnTokenWithChecks(listingId);
    }

    function burnBatch(uint256[] calldata listingIds) external {
        unchecked {
            for (uint256 i = 0; i < listingIds.length; ++i) {
                _burnTokenWithChecks(listingIds[i]);
            }
        }
    }

    // nft functions

    function _exists(uint256 id) internal override virtual view returns (bool) {
        return idToListing[id].curator != address(0);
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        for (uint256 i = 0; i < numAdded; ++i) {
            if (idToListing[i].curator == _owner) {
                ++balance;
            }
        }
    }

    function name() override external view returns (string memory) {
        return contractName;
    }

    function symbol() override external view returns (string memory) {
        return contractSymbol;
    }

    function totalSupply() override public view returns (uint256) {
        return numAdded - numRemoved;
    }

    function ownerOf(uint256 id) public override virtual view returns (address) {
        if (!_exists(id)) {
            revert NO_OWNER();
        }
        return idToListing[id].curator;
    }

    function tokenURI(uint256 token) override external view returns (string memory) {
        // TODO
        return '';
        // return renderer.tokenURI(token);
    }

    function contractURI() external override view returns (string memory) {
        // TODO
        return '';
        // return renderer.contractURI(token);
    }

    function _burnTokenWithChecks(uint256 listingId) internal {
        Listing memory _listing = idToListing[listingId];
        delete idToListing[listingId];
        unchecked {
            ++numRemoved;
        }

        // burn nft
        _burn(listingId);

        emit ListingRemoved(msg.sender, _listing);
    }

    function updateCurationPass(IERC721Upgradeable _curationPass) public onlyOwner {
        curationPass = _curationPass;

        emit TokenPassUpdated(msg.sender, address(_curationPass));
    }

    function pauseCuration() public onlyOwner {
        _setCurationPaused(true);
    }

    function resumeCuration() public onlyOwner {
        _setCurationPaused(false);
    }

    function _setCurationPaused(bool _setPaused) internal {
        if (_setPaused) {
            emit CurationPaused(msg.sender);
        } else {
            emit CurationResumed(msg.sender);
        }

        isPaused = _setPaused;
    }

    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {
        if (!curatorFactory.isValidUpgrade(_getImplementation(), _newImpl)) {
            revert INVALID_UPGRADE(_newImpl);
        }
    }
}
