/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// SPDX-License-Identifier: NOLICENSED
pragma solidity  0.8.0;

contract Number{
    uint public number = 1;

    event MyEvent(address indexed senderAddress, uint256 indexed value);
    
    function incrementNumber () public {
        number += 1;
    }

    function emityEvent() external {
        emit MyEvent(msg.sender, 99);
    }

    function deposit () external payable {

    }

    function getBalance() external view returns(uint256){
        return address(this).balance;
    }
}