/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// File: contracts/HotelRoom.sol


pragma solidity ^0.8.0;

contract MyContract {
    enum Statuses {
        Vacant,
        Occupied
    }
    Statuses public currentStatus;

    event Occupy(address _occupant, uint256 _value);
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        currentStatus = Statuses.Vacant;
    }

    modifier onlyWhileVacant() {
        // Check status
        require(currentStatus == Statuses.Vacant, "Currently occupied.");
        _;
    }

    modifier costs(uint256 _amount) {
        require(msg.value >= 2 ether, "Not enought ether provided.");
        _;
    }

    function book() public payable onlyWhileVacant costs(2 ether) {
        currentStatus = Statuses.Occupied;

        // owner.transfer(msg.value);
        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(true);

        emit Occupy(msg.sender, msg.value);
    }
}