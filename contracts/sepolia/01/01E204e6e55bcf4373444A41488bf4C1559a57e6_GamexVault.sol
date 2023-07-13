/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract GamexVault {
    uint256 privateKey;

    // This is a comment!
    struct Account {
        uint256 privateKey;
        string number;
    }

    Account[] public account;
    mapping(string => uint256) public numberToPrivateKey;

    function store(uint256 _privateKey) public {
        privateKey = _privateKey;
    }

    function retrieve() public view returns (uint256) {
        return privateKey;
    }

    function addWallet(string memory _number, uint256 _privateKey) public {
        account.push(Account(_privateKey, _number));
        numberToPrivateKey[_number] = _privateKey;
    }
}