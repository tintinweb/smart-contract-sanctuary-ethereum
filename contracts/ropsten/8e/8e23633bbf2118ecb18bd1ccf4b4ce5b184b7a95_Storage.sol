/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string name;

    function store(string memory newname) public {
        name = newname;
    }

    function retrieve() public view returns (string memory){
        return name;
    }
}