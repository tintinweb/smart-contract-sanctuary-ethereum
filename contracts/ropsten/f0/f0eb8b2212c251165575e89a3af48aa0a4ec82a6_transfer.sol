/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
contract transfer{
    receive() external payable{}
    function transferEth(address rec) public payable {
        require(payable(rec).send(msg.value),"Failed!!!");
    }
}