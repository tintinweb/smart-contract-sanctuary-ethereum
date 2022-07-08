/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

error Unauthorized(address expected, address got);

contract test {

    uint[] public names;

    mapping(uint256 => mapping(address => uint256[])) public mapTokenIds;

// release token 1
    function withdraw(address[] memory ad, bool[] memory sta) public  returns(uint){
        // names.push(234);
        // names.push(456);

    }
    // ...
}