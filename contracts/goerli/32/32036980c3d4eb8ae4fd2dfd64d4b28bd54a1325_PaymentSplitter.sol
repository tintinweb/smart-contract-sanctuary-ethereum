/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PaymentSplitter  {
    address payable [3] public recipients;
    event TransferReceived(address _from, uint _amount);

    function RCPs(address payable [3] memory _addrs) public  {
        for (uint i = 0; i < 3; i++) {
            recipients[i] = _addrs[i];
        }
    }
    
    function paymentAmount(uint _amnt) payable external{
        require(msg.value >= _amnt, "insufficient funds");
        _amnt = msg.value;
        uint256 share = _amnt / recipients.length; 

        for(uint i = 0; i < recipients.length; i++) {
            recipients[i].transfer(share);
        }    
        emit TransferReceived(msg.sender, _amnt);
    }      
}