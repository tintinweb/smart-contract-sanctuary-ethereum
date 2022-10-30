// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TestContract2 {
    uint256 public storageNum;

    // function initialize() public virtual initializer {}

    function setStorage(uint256 num) external returns (uint256) {
        storageNum = num;
        return storageNum;
    }

    // function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}