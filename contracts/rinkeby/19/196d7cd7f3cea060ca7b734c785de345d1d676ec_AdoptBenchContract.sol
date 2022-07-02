/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7.0;

contract AdoptBenchContract {

    address payable public owner;
    
    uint public constant BUY_PRICE = 0.001 ether;
    uint public constant EDIT_PRICE = 0.0001 ether;
    uint public constant TOTAL_SLOTS = 25;

    uint public freeSlots = 25;

    mapping(address=>string) public buyerToText;
    address[] public buyers;

    constructor(){
        owner = payable(msg.sender);
    }

    modifier notEmpty(string memory _value) {
        require(abi.encodePacked(_value).length > 0, "Message can't be empty!");
        _;
    }

    function addMessage(string memory _message) public payable notEmpty(_message)  {
        string memory senderValue = buyerToText[msg.sender];
        bytes memory valueBytes = abi.encodePacked(senderValue);

        if (valueBytes.length > 0) {
            editSlot(_message);
        } else {
            buySlot(_message);
        }
    }

    function getAllbuyersToTexts() public view returns(address[] memory, string[] memory) {
        address[] memory addresses = new address[](buyers.length);
        string[] memory messages = new string[](buyers.length);
        for (uint i = 0; i < TOTAL_SLOTS - freeSlots; i++) {
            addresses[i] = buyers[i];
            messages[i] = buyerToText[buyers[i]];
        }

        return (addresses, messages);
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawCash() public {
        owner.transfer(getContractBalance());
    }

    function editSlot(string memory _newMessage) private {
        require(msg.value >= EDIT_PRICE, "Not enough Ether to edit!");

        buyerToText[msg.sender] = _newMessage;
    }

    function buySlot(string memory _newMessage) private {
        require(msg.value >= BUY_PRICE, "Not enough Ether to buy!");
        require(freeSlots > 0, "No free slots!");

        buyerToText[msg.sender] = _newMessage;
        buyers.push(msg.sender);
        freeSlots = freeSlots - 1;
    }

}