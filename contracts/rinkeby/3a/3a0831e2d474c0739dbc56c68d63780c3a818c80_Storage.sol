/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

contract Storage {
    event HashUpdated(address caller, bytes32 hash);

    bytes32 hash;

    /**
     * @dev Store value in variable
     * @param h value to store
     */
    function store(bytes32 h) public {
        hash = h;
        emit HashUpdated(msg.sender, hash);
    }

    /**
     * @dev Return value 
     * @return value of 'hash'
     */
    function retrieve() public view returns (bytes32){
        return hash;
    }
}