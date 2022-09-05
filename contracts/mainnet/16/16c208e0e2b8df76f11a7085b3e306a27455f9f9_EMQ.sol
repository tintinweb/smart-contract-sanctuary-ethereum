/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EMQ {
    address owner;
    string _E;
    string _dochash;

    constructor() {
        owner = msg.sender;
    }

    function setE(string memory E) public {
        require(owner == msg.sender);
        _E = E;
    }

    function getE() public view returns (string memory) {
        return _E;
    }

    function setDocHash(string memory dochash) public {
        require(owner == msg.sender);
        _dochash = dochash;
    }

    function getDocHash() public view returns (string memory) {
        return _dochash;
    }

    fallback() external payable {
        
    }

    receive() external payable {
        
    }
}