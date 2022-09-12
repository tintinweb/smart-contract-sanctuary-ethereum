/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Wills
 * @dev Stores will hashes
 */
contract Wills {
    struct Will {
        string personName;
        string governmentId;
        uint256 willDocumentSha256;
    }

    address private _owner;

    Will[] public wills;

    constructor() {
        _owner = msg.sender;
    }

    function addWill(Will calldata will) onlyOwner public returns (uint) {
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