// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract FortuneWheel {
    uint256 public constant SEAT_PRICE = 1e16;
    uint private immutable CAPACITY;

    address[] private participants;

    constructor(uint _capacity) {
        require(_capacity > 0, "Capacity must be greater than 0");

        CAPACITY = _capacity;
    }

    function participate() public payable onlyNewAddress {
        require(msg.value == SEAT_PRICE, "Incorrect amount of ETH");

        participants.push(msg.sender);

        if (participants.length == CAPACITY) {
            reset(msg.sender);
        }
    }

    function reset(address winner) private {
        (bool sent, ) = payable(winner).call{value: address(this).balance}("");
        require(sent, "Transfer failed");

        participants = new address[](0);
    }

    modifier onlyNewAddress {
        for (uint i = 0; i < participants.length; ++i) {
            require(msg.sender != participants[i], "You have already participated");
        }
        _;
    }
}