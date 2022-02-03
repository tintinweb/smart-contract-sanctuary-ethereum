//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;

contract Owner {
    address private owner;

    event OwnerEvent(address old_owner, address new_owner);

    constructor() {
        owner = msg.sender;
        emit OwnerEvent(address(0), owner);
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address new_owner) public isOwner {
        owner = new_owner;
        emit OwnerEvent(owner, new_owner);
    }
    function getOwner () public view returns(address) {
        return owner; 
    }
}