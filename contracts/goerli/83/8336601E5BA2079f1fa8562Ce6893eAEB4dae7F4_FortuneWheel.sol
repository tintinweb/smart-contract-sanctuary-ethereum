// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract FortuneWheel {
    uint public immutable CAPACITY;
    uint256 public immutable SEAT_PRICE;
    address[] public participants;

    constructor(uint _capacity, uint256 _seat_price) {
        CAPACITY = _capacity;
        SEAT_PRICE = _seat_price;
    }

    function getParticipantsCount() public view returns (uint) {
        return participants.length;
    }

    function participate() public payable onlyNewAddress {
        require(msg.value == SEAT_PRICE, "Incorrect amount of ETH");
        participants.push(msg.sender);

        if (participants.length == CAPACITY) {
            participants = new address[](0);
            (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
            require(sent, "ETH transfer failed");
        }
    }

    modifier onlyNewAddress {
        for (uint i = 0; i < participants.length; i++) {
            require(participants[i] != msg.sender, "Address already participated");
        }
        _;
    }
}