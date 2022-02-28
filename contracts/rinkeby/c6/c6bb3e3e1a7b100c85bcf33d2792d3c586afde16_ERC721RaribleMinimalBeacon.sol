// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./UpgradeableBeacon.sol";

contract ERC721RaribleMinimalBeacon is UpgradeableBeacon {
    constructor(address impl) UpgradeableBeacon(impl) {

    }
}