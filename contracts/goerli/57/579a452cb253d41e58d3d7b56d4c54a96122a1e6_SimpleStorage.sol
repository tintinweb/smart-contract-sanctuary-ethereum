// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

error sameStorageValue();
error notOwner();
error msgValueZero();

contract SimpleStorage {

    uint  public storedData;  //Do not set 0 manually it wastes gas!
    uint  public ownerUnixTimeContract; 
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    event setOpenDataEvent(address indexed user, uint newValue); //Topics and other event arguments used for Foundry testing. Event arguments like this use gas in production so be careful.
    event setOwnerDataEvent(uint newOwnerUnixTime);
    event donateToOwnerEvent();

    function set(uint x) public {
        if(storedData == x) { revert sameStorageValue(); }        
        storedData = x;
        emit setOpenDataEvent(msg.sender, x); //Topic 1 (user) and other argument not indexed (newValue) for Foundry.
    }

    function setOwnerData() public {
        if(msg.sender != owner) { revert notOwner(); }        
        ownerUnixTimeContract = block.timestamp;
        emit setOwnerDataEvent(block.timestamp);
    }

    function donateToOwner() public payable {
        if(msg.value == 0) { revert msgValueZero(); }        
        payable(owner).transfer(address(this).balance);
        emit donateToOwnerEvent();
    }

}