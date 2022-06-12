/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Reward {
    address payable owner;
    mapping(address => mapping(string => bool)) public winners;
    mapping(address => bool) public winnersPaid;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function addWinner(string calldata gameNumber) external {
        winners[msg.sender][gameNumber] = true;
    }

    function rewardMe() public {
        require(
            winners[msg.sender]["game1"],
            // && winners[msg.sender]["game2"] &&
            // winners[msg.sender]["game3"] &&
            // winners[msg.sender]["game4"],
            "You have not won all games yet!"
        );
        require(!winnersPaid[msg.sender], "You have already been rewarded!");
        winnersPaid[msg.sender] = true;
        payable(msg.sender).transfer(1 ether);
    }

    function withdraw() external {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}