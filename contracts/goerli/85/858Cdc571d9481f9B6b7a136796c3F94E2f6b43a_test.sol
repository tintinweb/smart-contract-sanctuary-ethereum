/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract test {
    receive() payable external{}

    uint usd = 0.000000001 ether;

    function give() public payable {
        payable(address(msg.sender)).transfer(usd);
    }
}