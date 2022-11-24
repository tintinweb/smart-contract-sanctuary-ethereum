/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// 許可證
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract main {
    string public name;

    constructor() {
        name = "James 0.8.0";
    }

    // all above versions above 0.5.0 need to specify to storage variable location
    // memory - sotre data in chain memory, after finish function, the data will remove 
    //.       - 32byte read or write need cost 3 gas
    // storage - sotre data in blockchain
    //.        - use 32byte storage space need cost 20000 gas
    //.        - update existing data need cost 5000 gas
    // calldata - like memory, but read only, mostly use for parameter passing
    function setName(string memory _name) public {
        name = _name;
    }
}