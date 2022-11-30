/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
    contract Lottery {
        address manager;
        address payable[] players;

        constructor() {
            manager = msg.sender;
        }

        function getBalance() public view returns(uint){
            return address(this).balance;
    }

        function buyLottery() public payable {
        require(msg.value == 1 ether,"Please Buy with 1 ETh");
        players.push(payable(msg.sender));

        }

        function getLength() public view returns(uint){
        return players.length;

        }

        function randomNumber() public view returns(uint) {
            return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length))); 
    
        }

        function selectWinner() public{
            require(msg.sender == manager,"You aren't the Manager!");
            uint pick_num = randomNumber();
            address payable selected_winner;
            uint final_winner = pick_num % players.length;
            selected_winner = players[final_winner];
            selected_winner.transfer(getBalance());
            players = new address payable[](0);

        }

    }