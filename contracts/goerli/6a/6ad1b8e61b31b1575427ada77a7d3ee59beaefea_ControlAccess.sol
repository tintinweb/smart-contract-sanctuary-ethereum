/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ControlAccess{
    enum Status {PENDING,ACTIVATED,REVOKED}
    
    struct User{
        Status status;
        address owner;
        uint256 balance;
        uint256[] registers;
    }

    mapping(address=>User) public listOfUsers;
    address public hardwareAddress;
    address public ownerAddress;

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "You're not the owner");
        _;
    }

    modifier onlyHardware() {
        require(msg.sender == hardwareAddress, "You're not the hardware");
        _;
    }

    constructor(address _hardwareAddress, address _ownerAddress) {
        hardwareAddress = _hardwareAddress;
        ownerAddress = _ownerAddress;
    }
    
    function addCard(address _newCard) public onlyOwner{
        require(listOfUsers[_newCard].status == Status.PENDING, "This card was already activated" );
        User memory user = listOfUsers[_newCard];
        user.status = Status.ACTIVATED;
        user.owner = _newCard;
        listOfUsers[_newCard] = user;
    }

    function removeCard(address _card) public onlyOwner{
        require(listOfUsers[_card].status == Status.ACTIVATED, "This card is not activated" );
        User memory user = listOfUsers[_card];
        user.status = Status.REVOKED;
        listOfUsers[_card] = user;
    }

    function setBalance(uint256 _balance) public {
        require(listOfUsers[msg.sender].owner == msg.sender, "You're not the owner");
        require(listOfUsers[msg.sender].status == Status.ACTIVATED, "This card is not activated");
        User memory user = listOfUsers[msg.sender];
        user.balance += _balance;
        listOfUsers[msg.sender] = user;
    }

    function enter(address _card) public onlyHardware {
        require(listOfUsers[_card].status == Status.ACTIVATED, "This card is not activated");
        User storage user = listOfUsers[_card];
        user.registers.push(block.timestamp);
        listOfUsers[_card] = user;
    }

    function getRegisters(address _card) public view returns(uint256[] memory){  
        return listOfUsers[_card].registers;
    }
}