/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

pragma solidity ^0.8.17;

contract Lottery {
    address public manager;
    address[] public players;
    address payable public lastWinner;
    
    constructor() {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value == .05 ether);
        players.push(msg.sender);

        if (address(this).balance >= 0.1 ether) {
            pickWinner();
        }
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function pickWinner() private {
        uint index = random() % players.length;
        lastWinner = payable(players[index]);
        lastWinner.transfer(address(this).balance);
        players = new address[](0);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function withdrawAll() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}