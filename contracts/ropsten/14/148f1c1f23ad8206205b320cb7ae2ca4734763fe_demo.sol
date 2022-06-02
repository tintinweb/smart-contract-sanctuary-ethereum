/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.23;
contract demo{
    uint a;
function set(uint _a)public {
    a = _a;
}
function get()public view returns(uint){
    return a;
}
}