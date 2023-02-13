/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ArkhiiveWills
 * @dev Stores Arkhiive Will hashes
 */
contract ArkhiiveWills {
    struct ArkhiiveWill {
        string arkhiiveCatalogId;
        uint256 willDocumentSha256;
    }

    address private _owner;

    ArkhiiveWill[] public wills;

    constructor() {
        _owner = msg.sender;
    }

    function addWill(ArkhiiveWill calldata will) onlyOwner public returns (uint) {
        wills.push(will);
        return wills.length - 1;
    }

    function _checkOwner() internal view virtual {
        require(_owner == msg.sender, "Caller is not the owner");
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }
}