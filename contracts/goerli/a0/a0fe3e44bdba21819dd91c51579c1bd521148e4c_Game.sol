/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {

    uint balance;

    address payable public owner;
    mapping(uint => address payable) public players;

    enum Game_Status{
        OPEN,
        WAITING,
        CLOSED
    }

    Game_Status status;

    constructor(){
        owner = payable(msg.sender);
    }

    // fallback() external payable{}
    receive() external payable{}

    // to get the game state (CALL)
    function getGameState() external view returns (Game_Status){
        return status;
    }

    // to set the game state to another state (TRANSACTION)
    function setGameState(Game_Status _status) public {
        //	30737 gas
        status = _status;
    }

    // to get the balance of the smart contract (CALL)
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // // to transfer the money to the contract's address (TRANSACTION)
    // function receive() public payable {
    //     balance += msg.value;
    // }

    // to add a new player to the game (TRANSACTION)
    function addPlayer(address payable _newPlayer, uint8 _position) public {
        players[_position] = payable(_newPlayer);
    }

    function payFromContract(address payable _addr) payable public {
        _addr.transfer(address(this).balance);
    }

}