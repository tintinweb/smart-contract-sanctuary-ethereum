/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract childContract {

    string public name;

    constructor(string memory _name) {
    name = _name;
  }
}

contract testFactory {

    childContract public child;

function deployChild(string memory _name) public
    {
    child = new childContract(_name);
    }
}