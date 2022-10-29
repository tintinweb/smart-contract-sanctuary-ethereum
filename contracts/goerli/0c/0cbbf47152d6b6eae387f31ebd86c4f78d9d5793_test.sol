// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;



contract test {

    bytes[] public powerLevels;

    function setWeaponPowerLevels(bytes[] memory _powerLevels) external {
        powerLevels = _powerLevels;
    }
}