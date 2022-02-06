/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    address payable[] public players;
    address public manager;

    event Print(string _name, address _value);

    constructor(){
        manager = msg.sender;
    }

    receive() external payable{
        require(msg.value ==  0.1 ether, "Lottery entry must be exactly 0.1 ether");
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager, "Only the contract owner can get the balance");
        return address(this).balance;
    }

    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public{
        require(msg.sender == manager, "Only the contract owner can pick the winner");
        require(players.length >= 3, "There must be at least 3 players to run the lottery");

        uint r = random();
        address payable winner;

        uint index = r % players.length;
        winner = players[index];

        winner.transfer(getBalance());
        emit Print("Winner", winner);

        players = new address payable[](0); // resets the array after payment is made

    }

}