/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public participants;
    
    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value == 1 ether);
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint256) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function getRandom() public view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length))); //DO NOT USE THIS IN PRODUCTION
    }

    function selectWinner() public  {
        require(msg.sender == manager);
        require(participants.length >= 3);

        uint random = getRandom();
        uint index = random % participants.length;
        address payable winner = participants[index];

        winner.transfer(getBalance());

        participants = new address payable[](0); //reset participants
    }
}