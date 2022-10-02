// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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

    event SetRenderer(address);

    event CurationPauseUpdated(address indexed owner, bool isPaused);

    event CurationResumed(address indexed owner);

    event UpdatedCurationLimit(uint256 newLimit);

    event UpdatedSortOrder(uint256[], int32[], address);

    event ScheduledFreeze(uint256);

    event NameUpdated(string newName);

    error PASS_REQUIRED();

    error ONLY_CURATOR();

    error WRONG_CURATOR_FOR_LISTING(address setCurator, address expectedCurator);

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
        bool _pause,
        uint256 _curationLimit,
        address _renderer,
        bytes memory _rendererInitializer,
        Listing[] memory _initialListings
    ) external;
}
