// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

contract SimpleContract {
    uint public constant VERSION = 1;
    uint public version;

    function setVersion(uint _version) external {
        version = _version;
    }
}