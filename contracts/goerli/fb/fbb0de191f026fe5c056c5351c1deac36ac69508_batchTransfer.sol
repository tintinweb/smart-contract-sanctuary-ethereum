/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract batchTransfer{
       function contribute()payable public  {
    }
    function batchTransfers( address  payable [] calldata receipents) payable  public {
        for( uint256 i = 0; i<receipents.length; i++){
        address payable recv = receipents[i];
        recv.transfer(msg.value);
        }
    }

}