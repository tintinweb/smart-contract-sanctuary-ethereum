// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hello {
    string public message;

    event EtherSent(address originalSender, uint256 amount); 
 
    bool flag; 
   
    constructor(string memory initialMessage) {
        message = initialMessage;
    }
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    function fundProxy() public payable {} 

    modifier nonReentrant() { 
        require(flag == false); 
        flag = true; 
        _; 
        flag = false;  
    } 

    function sendEther(address destAddress, address fromAddress) public nonReentrant { 
 
        // send the ether owned by Proxy 
        uint256 sentBalance = address(this).balance / 10; // sending 10% of the balance 
        emit EtherSent(msg.sender, sentBalance); 
 
        destAddress.delegatecall;
 
         
    } 
}