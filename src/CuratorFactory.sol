// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { UUPS } from "./lib/proxy/UUPS.sol";
import { Ownable } from "./lib/utils/Ownable.sol";
import { ERC1967Proxy } from "./lib/proxy/ERC1967Proxy.sol";

import { ICurator, Curator } from "./Curator.sol";

interface ICuratorFactory {
    event CuratorDeployed(address);

    function isValidUpgrade(address baseImpl, address newImpl) external view returns (bool);
}

contract CuratorFactoryStorageV1 {
    mapping(address => mapping(address => bool)) internal isUpgrade;
}

contract CuratorFactory is ICuratorFactory, UUPS, Ownable, CuratorFactoryStorageV1 {
    address public immutable curatorImpl;

    bytes32 private immutable curatorHash;

    constructor(address _curatorImpl) payable initializer {
        curatorImpl = _curatorImpl;

        curatorHash = keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_curatorImpl, "")));
    }

    function initialize(address _owner) external initializer {
        __Ownable_init(_owner);
    }

    function deploy(
        address _curationManager,
        string memory _title,
        address _tokenPass,
        uint40 _curationLimit,
        bool _initialPause
    ) external returns (address curator) {
        curator = address(new ERC1967Proxy(curatorImpl, ""));

        ICurator(curator).initialize(_curationManager, _title, _tokenPass, _curationLimit, _initialPause);

        emit CuratorDeployed(curator);
    }

    function isValidUpgrade(address _baseImpl, address _newImpl) external view returns (bool) {
        return isUpgrade[_baseImpl][_newImpl];
    }

    function _authorizeUpgrade(address _newImpl) internal override onlyOwner {}
}
