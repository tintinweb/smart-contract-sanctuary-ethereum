/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EtherGame {
    uint public targetAmount = 0.05 ether;
    address public winner;
    event Played(address player, uint amount);
    event ClaimRewarded(address winner, uint amount);

    function play() public payable {
        emit Played(msg.sender, msg.value);
        require(msg.value == 0.01 ether, "you can only send 1 Ether");
        uint balance = address(this).balance;
        require(balance < targetAmount, "game over");
        if (balance == targetAmount) {
            winner = msg.sender;
        }
    }

    function claimReward() public {
        require(msg.sender == winner, "you are not winner");
        uint reward =  address(this).balance;
        (bool sent, ) = msg.sender.call{value:reward}("");
        require(sent, "Failed to send Ether");
        emit ClaimRewarded(msg.sender, reward);
    }
}