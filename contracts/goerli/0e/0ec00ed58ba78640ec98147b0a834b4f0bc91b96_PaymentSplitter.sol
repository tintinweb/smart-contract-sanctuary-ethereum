/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT

contract PaymentSplitter {
    address payable public service_wallet;

    event TransferReceived(address _from, address _recipient, uint _amount);

    constructor(address payable _addrs) {
        service_wallet = _addrs;
    }

    function setReceiver(address payable recipient) payable external { 
        uint256 serviceFee = msg.value * 20 / 100; //getting 20%
        recipient.transfer(msg.value - serviceFee);
        service_wallet.transfer(serviceFee);
        emit TransferReceived(msg.sender, recipient, msg.value - serviceFee);
    
    }
}