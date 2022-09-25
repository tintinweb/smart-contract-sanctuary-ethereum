/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    bytes32 payload;


    function store(bytes32 pl) public {
        payload = pl;
    }

    function retrieve() public view returns (bytes32){
        return payload;
    }
}