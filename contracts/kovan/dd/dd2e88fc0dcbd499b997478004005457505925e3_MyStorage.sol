/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract MyStorage {

struct t {
    uint256 number;
    address mio;
}

t public am;

t public am2;

uint public x;

address public y;


    
    function store(t memory numa) public {
        t storage af;
        af = am;
        am = numa;
        x = af.number;
        y = af.mio;
        af = am2;
        

    }

    
}