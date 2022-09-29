// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { UUPS } from "./lib/proxy/UUPS.sol";
import { Ownable } from "./lib/utils/Ownable.sol";
import { ERC1967Proxy } from "./lib/proxy/ERC1967Proxy.sol";
import { ICuratorFactory } from "./interfaces/ICuratorFactory.sol";
import { ICurator } from "./interfaces/ICurator.sol";
import { Curator } from "./Curator.sol";

contract CuratorFactoryStorageV1 {
    mapping(address => mapping(address => bool)) internal isUpgrade;
}

contract CuratorFactory is ICuratorFactory, UUPS, Ownable, CuratorFactoryStorageV1 {
    address public immutable curatorImpl;
    address public immutable defaultMetadataRenderer;

    bytes32 private immutable curatorHash;

    constructor(address _curatorImpl, address _defaultMetadataRenderer) payable initializer {
        curatorImpl = _curatorImpl;
        defaultMetadataRenderer = _defaultMetadataRenderer;

        curatorHash = keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_curatorImpl, "")));
    }

    function initialize(address _owner) external initializer {
        __Ownable_init(_owner);
    }

    function deploy(
        address curationManager,
        string memory name,
        string memory symbol,
        address tokenPass,
        bool initialPause,
        uint256 curationLimit,
        address renderer,
        bytes memory rendererInitializer
    ) external returns (address curator) {
        if (renderer == address(0x0)) {
            renderer = defaultMetadataRenderer;
        }
        curator = address(
            new ERC1967Proxy(
                curatorImpl,
                abi.encodeWithSelector(
                    ICurator.initialize.selector,
                    curationManager,
                    name,
                    symbol,
                    tokenPass,
                    initialPause,
                    curationLimit,
                    renderer,
                    rendererInitializer
                )
            )
        );

        emit CuratorDeployed(curator, curationManager, msg.sender);
    }

    function isValidUpgrade(address _baseImpl, address _newImpl) external view returns (bool) {
        return isUpgrade[_baseImpl][_newImpl];
    }

    function addValidUpgradePath(address _baseImpl, address _newImpl) external onlyOwner {
        isUpgrade[_baseImpl][_newImpl] = true;
        emit RegisteredUpgradePath(_baseImpl, _newImpl);
    }

    function _authorizeUpgrade(address _newImpl) internal override onlyOwner {}
}
