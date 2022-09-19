// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { UUPS } from "./lib/proxy/UUPS.sol";
import { Ownable } from "./lib/utils/Ownable.sol";
import { ICuratorFactory } from "./CuratorFactory.sol";
import { IERC721 } from "./lib/interfaces/IERC721.sol";

interface ICurator {
    event ListingAdded(address indexed curator, address indexed listing);

    event ListingRemoved(address indexed curator, address indexed listing);

    event TitleUpdated(address indexed owner, string title);

    event TokenPassUpdated(address indexed owner, address tokenPass);

    event CurationPaused(address indexed owner);

    event CurationResumed(address indexed owner);

    error PASS_REQUIRED();

    error ONLY_CURATOR();

    error CURATION_PAUSED();

    error CURATION_FROZEN();

    error LISTING_EXISTS();

    function initialize(
        address manager,
        string memory title,
        address tokenPass,
        bool pause
    ) external;
}

contract CuratorStorageV1 {
    string public title;

    IERC721 public tokenPass;

    uint40 internal numAdded;

    uint40 internal numRemoved;

    bool internal isPaused;

    /// @dev Listing id => Listing address
    mapping(uint256 => address) internal idToListing;

    /// @dev Listing address => Listing id
    mapping(address => uint256) internal listingToId;

    /// @dev Listing address => Curator
    mapping(address => address) internal curators;
}

contract Curator is ICurator, UUPS, Ownable, CuratorStorageV1 {
    ICuratorFactory private immutable curatorFactory;

    constructor(address _curatorFactory) payable initializer {
        curatorFactory = ICuratorFactory(_curatorFactory);
    }

    function initialize(
        address _owner,
        string memory _title,
        address _tokenPass,
        bool _pause
    ) external initializer {
        __Ownable_init(_owner);

        title = _title;

        tokenPass = IERC721(_tokenPass);

        if (_pause) {
            isPaused = true;

            emit CurationPaused(_owner);
        }
    }

    function getListings() external view returns (address[] memory activeListings) {
        unchecked {
            activeListings = new address[](numAdded - numRemoved);

            uint256 activeIndex;

            for (uint256 i; i < numAdded; ++i) {
                address listing = idToListing[i];

                if (listing == address(0)) continue;

                activeListings[activeIndex] = listing;

                ++activeIndex;
            }
        }
    }

    function addListing(address _listing) external {
        if (isPaused) revert CURATION_PAUSED();

        if (tokenPass.balanceOf(msg.sender) == 0) revert PASS_REQUIRED();

        _addListing(_listing);
    }

    function ownerAddListing(address _listing) external onlyOwner {
        _addListing(_listing);
    }

    function _addListing(address _listing) internal {
        if (curators[_listing] != address(0)) revert LISTING_EXISTS();

        uint256 listingId;

        unchecked {
            listingId = numAdded++;
        }

        idToListing[listingId] = _listing;

        listingToId[_listing] = listingId;

        curators[_listing] = msg.sender;

        emit ListingAdded(msg.sender, _listing);
    }

    function removeListing(address _listing) external {
        if (isPaused) revert CURATION_PAUSED();

        if (msg.sender != curators[_listing]) revert ONLY_CURATOR();

        _removeListing(_listing);
    }

    function ownerRemoveListing(address _listing) external onlyOwner {
        _removeListing(_listing);
    }

    function _removeListing(address _listing) internal {
        uint256 id = listingToId[_listing];

        delete idToListing[id];

        delete listingToId[_listing];

        delete curators[_listing];

        unchecked {
            ++numRemoved;
        }

        emit ListingRemoved(msg.sender, _listing);
    }

    function updateTitle(string memory _title) public onlyOwner {
        title = _title;

        emit TitleUpdated(msg.sender, _title);
    }

    function updateTokenPass(IERC721 _tokenPass) public onlyOwner {
        tokenPass = _tokenPass;

        emit TokenPassUpdated(msg.sender, address(_tokenPass));
    }

    function pauseCuration() public onlyOwner {
        isPaused = true;

        emit CurationPaused(msg.sender);
    }

    function resumeCuration() public onlyOwner {
        delete isPaused;

        emit CurationResumed(msg.sender);
    }

    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {
        if (!curatorFactory.isValidUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}
