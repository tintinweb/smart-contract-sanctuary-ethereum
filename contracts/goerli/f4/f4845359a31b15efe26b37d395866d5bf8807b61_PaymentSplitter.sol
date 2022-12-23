/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PaymentSplitter  {
    address public owner;
    address payable [] public recipients;
    event TransferReceived(address _from, uint _amount);

    modifier isOwner() {
        // only the owner can do this
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setWorkers(address payable [] memory _addrs) isOwner public {
        delete recipients;

        for(uint256 i = 0; i < _addrs.length; ++i){
            recipients.push(_addrs[i]);
        }
    }
    
    receive() payable external {
        uint256 share = msg.value / recipients.length; 

        for(uint256 i = 0; i < recipients.length; ++i){
            recipients[i].transfer(share);
        }    
        emit TransferReceived(msg.sender, msg.value);
    }      
}