/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {

    address public owner;
    address public winner = address(0);

    uint256 ticketFee = 0.1 ether;
 
    address[] public participants;

    constructor() {
        owner = msg.sender;
    }
  
    function purchaseTicket() public payable {
        require(msg.value >= ticketFee);
        require(msg.sender != owner);
        require(winner == address(0));

        participants.push(msg.sender);
    }

    function announceWinner() public {
        require(msg.sender == owner);
        require(winner == address(0));
        require(participants.length >= 3);

        uint256 seed = uint256(keccak256(abi.encodePacked(participants, block.number)));
        winner = participants[seed % participants.length];
    }

    function withdraw() external {
        require(msg.sender == winner);

        uint256 balance = address(this).balance;
        payable(winner).transfer(balance);
    }
}