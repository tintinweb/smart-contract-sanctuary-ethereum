/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error Lottery__UnauthorizedAccess();
error Lottery__NotEnoughETH();
error Lottery__NotEnoughParticipants();

contract Lottery {
    address private immutable s_manager;
    address payable[] private s_participants;

    event WinnerDeclared(address winner, uint amount);

    modifier onlyManager {
        if(msg.sender != s_manager) {
            revert Lottery__UnauthorizedAccess();
        }
        _;
    }

    constructor() {
        s_manager = msg.sender;
    }

    function manager() public view returns(address) {
        return s_manager;
    }

    function participate() public payable {
        if(msg.value < 1 gwei) {
            revert Lottery__NotEnoughETH();
        }

        s_participants.push(payable(msg.sender));
    }

    function balanceOf() public view onlyManager returns(uint) {
        return address(this).balance;
    }

    function genRandom() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, s_participants.length)));
    }

    function declareWinner() public payable onlyManager {
        if(s_participants.length < 3) {
            revert Lottery__NotEnoughParticipants();
        }

        address payable winner = s_participants[genRandom() % s_participants.length];
        uint amount = balanceOf();

        winner.transfer(amount);

        s_participants = new address payable[](0);

        emit WinnerDeclared(winner, amount);
    }
}