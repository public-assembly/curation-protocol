// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ICuratorFactory {
    event CuratorDeployed(address);

    function isValidUpgrade(address baseImpl, address newImpl) external view returns (bool);
}
