/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract SimpleStorage {
    string name;
    event myEvent(string name);

    function set(string memory _name) public {
        name = _name;
    }

    function get() public view returns (string memory) {
        return name;
    }

    function eventEmit(string memory evName) public returns(string memory) {
        emit myEvent(evName);
        return evName;
    }
}