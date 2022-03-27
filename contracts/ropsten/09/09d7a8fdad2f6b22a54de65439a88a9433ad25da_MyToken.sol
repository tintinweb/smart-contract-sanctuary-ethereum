/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

pragma solidity >= 0.8.13;
// SPDX-License-Identifier: MIT

contract MyToken {
    uint256 public price = 1 ether;
    uint public decimals;
    uint mult_dec;
    mapping (address => uint) public balanceOf;

    function token() public payable {
        decimals = 2;
        mult_dec = 10**decimals;
    }
    function withdraw(uint amount, address payable destAddr) private {

        destAddr.transfer(amount);
     
    }
}