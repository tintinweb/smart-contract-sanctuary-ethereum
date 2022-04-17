/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// File: fund_me.sol

contract SimpleStorage{

    address payable[] public players;
    address public manager;
    uint256 public favouriteNumber;

    function store(uint256 a) public {
        favouriteNumber = a;
        // favouriteBool;
    }

    constructor(){
        manager = msg.sender;
    }

    receive () payable external{
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }


    function pickWinner() public{

        require(msg.sender == manager);
        require (players.length >= 3);

        uint r = random();
        address payable winner;


        uint index = r % players.length;

        winner = players[index];

        winner.transfer(getBalance());


        players = new address payable[](0);
    }

}