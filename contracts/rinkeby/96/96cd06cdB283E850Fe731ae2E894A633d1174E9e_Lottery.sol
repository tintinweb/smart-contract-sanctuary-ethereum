/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity ^0.8.15;

contract Lottery{
    address public manager;
    uint private amount; //Minimal amount to enter in the contract
    address[] private players;

    //Constructor
    constructor(uint Amount){
        manager = msg.sender;
        amount = Amount;
    }

    //Accessor
    function getPlayers() public view returns (address[] memory){
        return players;
    }

    //Methods
    function enter() public payable{
        require(msg.value == amount * 1 ether);
        players.push(msg.sender);
    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public onlyManager{
        uint index = random() % players.length;
        address payable winner = payable(players[index]);
        winner.transfer(address(this).balance);
        players = new address[](0);  //(0) => Initial size of the dynamic array
    }

    //Modifier
    modifier onlyManager(){  // Modifier function => Factorise code
        require(msg.sender == manager);
        _; // All the code will go there
    }
}