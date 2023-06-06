// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ReceiveEther {

    event UpdateRecipient(address indexed _recipient);

    function getBalance() public view returns (uint) {
       return address(msg.sender).balance;
    }

    address public recipient;

    function setRecipient(address _recipient)public {
        recipient=_recipient;
        emit UpdateRecipient(_recipient);
    }

    function transfer(uint256 _amount)  public payable {
        uint userBalance = address(msg.sender).balance;
         (bool sent, bytes memory data) = recipient.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }


}