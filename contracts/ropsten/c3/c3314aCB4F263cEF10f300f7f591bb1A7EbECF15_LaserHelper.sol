// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

interface ILaser {
    function owner() external view returns (address);

    function getGuardians() external view returns (address[] memory);

    function getRecoveryOwners() external view returns (address[] memory);

    function singleton() external view returns (address);

    function isLocked() external view returns (bool);

    function getConfigTimestamp() external view returns (uint256);

    function nonce() external view returns (uint256);
}

/**
 * @title LaserHelper
 *
 * @notice Allows to batch multiple requests in a single rpc call.
 */
contract LaserHelper {
    function getLaserState(address laserWallet)
        external
        view
        returns (
            address owner,
            address[] memory guardians,
            address[] memory recoveryOwners,
            address singleton,
            bool isLocked,
            uint256 configTimestamp,
            uint256 nonce,
            uint256 balance
        )
    {
        ILaser laser = ILaser(laserWallet);

        owner = laser.owner();
        guardians = laser.getGuardians();
        recoveryOwners = laser.getRecoveryOwners();
        singleton = laser.singleton();
        isLocked = laser.isLocked();
        configTimestamp = laser.getConfigTimestamp();
        nonce = laser.nonce();
        balance = address(laserWallet).balance;
    }
}