/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Self {
    function t() public payable {
        address payable addr = payable(address(this));
        selfdestruct(addr);
    }
    
}