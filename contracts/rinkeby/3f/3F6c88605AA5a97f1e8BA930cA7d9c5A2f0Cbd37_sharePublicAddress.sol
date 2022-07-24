/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract sharePublicAddress {
    mapping(address => bytes32) private _privateRegister;
    mapping(bytes32 => address) private _privateReverseLookup;

    function registerAccountWithKeyCode(string calldata keyCode) public {
        if (!isAccountAlreadyRegistered(msg.sender)) {
            bytes32 keyHash = sha256(abi.encodePacked(keyCode));
            _privateRegister[msg.sender] = keyHash;
            _privateReverseLookup[keyHash] = msg.sender;
        }
    }

    function isAccountAlreadyRegistered(address account) private view returns (bool) {
        if (_privateRegister[account] != "") {
            return true;
        }
        return false;
    }

    function findAccountWithKeyCode(string calldata keyCode) public returns (address) {
        bytes32 keyHash = sha256(abi.encodePacked(keyCode));
        address entry = _privateReverseLookup[keyHash];
        if (entry != address(0)) {
            deleteEntries(entry);
        }
        return entry;
    }

    function deleteEntries(address account) private {
        if (isAccountAlreadyRegistered(account)) {
            bytes32 keyCode = _privateRegister[account];
            delete _privateRegister[account];
            delete _privateReverseLookup[keyCode];
        }
        require(isAccountAlreadyRegistered(account) == false);
    }

    function unRegister() public {
        deleteEntries(msg.sender);
    }
}