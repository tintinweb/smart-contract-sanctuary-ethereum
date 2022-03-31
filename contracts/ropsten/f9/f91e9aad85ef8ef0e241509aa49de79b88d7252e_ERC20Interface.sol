/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

pragma solidity 0.6.9;
// SPDX-License-Identifier: MIT

contract ERC20Interface {
   }
// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
    }
}

contract ONELOVE is ERC20Interface, SafeMath {
    bytes32 public name= "ONELOVE";
    bytes32 public symbol = "ONE";
    uint8 public decimals = 2; 
    uint256 public _totalSupply = 100000000000;
    
}