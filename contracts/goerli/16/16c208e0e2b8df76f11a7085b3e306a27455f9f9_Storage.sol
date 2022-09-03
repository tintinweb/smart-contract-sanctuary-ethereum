/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    address owner;
    string dochash;

    constructor() {
        owner = msg.sender;
    }

    function setDocHash(string memory _dochash) public {
        require(owner == msg.sender);
        dochash = _dochash;
    }

    function getDocHash() public view returns (string memory) {
        return dochash;
    }

    fallback() external payable {
        
    }

    receive() external payable {
        
    }
}