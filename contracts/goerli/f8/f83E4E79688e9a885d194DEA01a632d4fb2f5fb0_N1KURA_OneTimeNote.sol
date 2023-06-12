// SPDX-License-Identifier: N1KURA
// Created by N1KURA
// GitHUB: https://github.com/N1KURA
// Twitter: https://twitter.com/0xN1KURA
// Telegram: https://t.me/N1KURA

pragma solidity ^0.8.20;

contract N1KURA_OneTimeNote {
    address owner; // address of the note owner
    string note; // variable for storing the note
    address recipient; // address of the recipient of the note
    bool sent; // flag indicating whether the note has been sent
    
    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    // Creates a new note
    function write(string memory newNote) public onlyOwner {
        require(!sent, "Note has already been sent, cannot be modified");
        note = newNote;
    }
    
    // Sends the note to the recipient
    function send(address receiver) public onlyOwner {
        require(!sent, "Note has already been sent, cannot be sent again");
        recipient = receiver;
        sent = true;
    }
    
    // Returns the current value of the note
    function getNote() public view returns (string memory) {
        return note;
    }
    
    // Transfers ownership of the note to another user
    function transfer(address newOwner) public onlyOwner {
        require(sent, "Note has not been sent yet, cannot be transferred");
        owner = newOwner;
    }
    
    // Deletes the note and returns all funds to the note owner
    function deleteNote() public onlyOwner {
        require(!sent, "Note has already been sent, cannot be deleted");
        address payable recipientPayable = payable(owner);
        recipientPayable.transfer(address(this).balance);
    }
    
    // Transfers ownership of the note to the recipient and returns any funds sent with the note
    function claimNote() public {
        require(msg.sender == recipient, "You are not the intended recipient of this note");
        require(sent, "Note has not been sent yet");
        recipient = address(0);
        owner = msg.sender;
    }
    
    // Withdraws all funds from the contract to the note owner
    function withdraw() public onlyOwner {
        require(sent, "Note has not been sent yet, cannot be withdrawn");
        payable(owner).transfer(address(this).balance);
    }
}