// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IAccessControlRegistry } from "onchain-modules/interfaces/IAccessControlRegistry.sol";

interface ICuratorInfo {
    function name() external view returns (string memory);

    function accessControl() external view returns (IAccessControlRegistry);

    function owner() external view returns (address);
}
