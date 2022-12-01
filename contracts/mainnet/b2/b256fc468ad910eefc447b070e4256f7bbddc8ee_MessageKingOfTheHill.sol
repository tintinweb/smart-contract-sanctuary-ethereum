// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MessageKingOfTheHill {
    string public topMessage;
    uint256 public highestPrice;
    address public highestBidder;

    function publish(string memory proposedMessage) public payable {
        if (msg.value > highestPrice) {
            //Send money back to prior highest bidder
            (bool sent,) = payable(highestBidder).call{value: highestPrice}("");
            require(sent, "Failed to send Ether");

            //Update to new message
            topMessage = proposedMessage;
            //Update to new high bid
            highestPrice = msg.value;
            //Update new highest bidder address
            highestBidder = msg.sender;
        }
        else {
            revert();
        }
    }
}