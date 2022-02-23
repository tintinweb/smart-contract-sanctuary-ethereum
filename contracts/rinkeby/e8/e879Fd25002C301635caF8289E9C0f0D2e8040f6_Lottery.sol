/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function getCount() public view returns(uint) {
        return players.length;
    }

    function enter() public payable{
        // Stops to see if the function should continue
        // In this case we want ether sent, by default it is
        // in wei.
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }

    function pickWinner() public restricted{
        // Psudo random
        uint index = random() % players.length;

        // Address has transfer function (in wei)
        payable(players[index]).transfer(address(this).balance);

        // Clear array
        players = new address[](0);
    }

    // View does not modify data in contract
    function getPlayers() public view returns (address[] memory){
        return players;
    }

    function random() private view returns (uint) {
        // Turns hash into unsigned number to return
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    modifier restricted(){
        // Only the creator of the contract
        // can pick a winner.
        require(msg.sender == manager);

        // Underscore is like a target where
        // code is inserted.
        _;
    }
    
}