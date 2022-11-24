/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

pragma solidity ^0.8.15;
// SPDX-License-Identifier: MIT

contract PaymentSplitter  {
    address payable [] public recipients;
    event TransferReceived(address _from, uint _amount);
    
    constructor(address payable [] memory _addrs) {
        for(uint i=0; i<_addrs.length; i++){
            recipients.push(_addrs[i]);
        }
    }
    
    receive() payable external {
        uint256 share = msg.value / recipients.length; 

        for(uint i=0; i < recipients.length; i++){
            recipients[i].transfer(share);
        }    
        emit TransferReceived(msg.sender, msg.value);
    }      
}