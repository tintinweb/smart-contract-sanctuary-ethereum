/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity >= 0.8.13;
// SPDX-License-Identifier: MIT

    contract ZOB {
    bytes8 public name = "ZingZing";
    bytes32 public symbol ="ZOB";
    uint256 public price = 1.5 ether;
    uint public decimals;
    uint mult_dec;
    uint256 public initialSupply = 100000000000;
    uint256 public totalSupply = initialSupply;
    mapping (address => uint) public balanceOf;

    function token () public payable {
        decimals = 2;

    }
    function withdraw(uint amount, address payable destAddr) private {

        destAddr.transfer(amount);
     
    }    
}