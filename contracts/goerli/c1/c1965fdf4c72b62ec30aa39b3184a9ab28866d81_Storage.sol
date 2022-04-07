/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    string[] note;

    /**
     * @dev Store value in variable
     * @param message value to store
     */
    function store(string memory message) public {
        note.push(message);
    }

    /**
     * @dev Return value 
     * @return value of note
     */
    function retrieve() public view returns (string[] memory){
        return note;
    }
}