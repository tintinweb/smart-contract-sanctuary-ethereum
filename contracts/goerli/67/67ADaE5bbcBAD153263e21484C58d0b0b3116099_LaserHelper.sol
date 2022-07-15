// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

interface ILaser {
    function owner() external view returns (address);

    function singleton() external view returns (address);

    function timeLock() external view returns (uint256);

    function isLocked() external view returns (bool);

    function guardiansLocked() external view returns (bool);

    function getGuardians() external view returns (address[] memory);

    function getRecoveryOwners() external view returns (address[] memory);

    function nonce() external view returns (uint256);
}

/**
 * @title LaserHelper - Helper contract that outputs multiple results in a single call.
 */
contract LaserHelper {
    function getResults(address _laser)
        external
        view
        returns (
            address owner,
            address singleton,
            uint256 timeLock,
            bool isLocked,
            bool guardiansLocked,
            address[] memory guardians,
            address[] memory recoveryOwners,
            uint256 nonce
        )
    {
        ILaser laser = ILaser(_laser);
        owner = laser.owner();
        singleton = laser.singleton();
        timeLock = laser.timeLock();
        isLocked = laser.isLocked();
        guardiansLocked = laser.guardiansLocked();
        guardians = laser.getGuardians();
        recoveryOwners = laser.getRecoveryOwners();
        nonce = laser.nonce();
    }
}