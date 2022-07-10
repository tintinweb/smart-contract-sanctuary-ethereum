/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract OnChain {
    
    event MessageSent(address indexed _sender, address indexed _receiver, string _message, uint256 _value);
    event AddressBlocked(address indexed _sender, address _blockedAddress);
    
    mapping (address => mapping (address => bool)) public blocked;
    
    uint256 public message_staling_period = 25 days;
    
    function sendMessage(address _receiver, string memory _message) public payable
    {
        require(!blocked[_receiver][msg.sender], "Message can't be sent, recipient blocked your address" );
        (bool success,) = _receiver.call{value: msg.value}(bytes(_message));
        require(success, "Message sending failed");
        emit MessageSent(msg.sender, _receiver, _message, msg.value);
    }
    
   function blockAddress(address _address) public
   {
        blocked[msg.sender][_address] = true;
        emit AddressBlocked(msg.sender, _address);
   }
}