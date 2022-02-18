/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity ^0.4.24;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() public {
        manager = msg.sender;
    }
    function enter() public payable {
        require(msg.value > 0.1 ether);
        players.push(msg.sender);
    }
    function pseudoRandom() private view returns (uint) {
        return uint(
            keccak256(
                abi.encodePacked(block.difficulty, now, players)
            )
        );
    }
    function selectWinner() public managerOnly {
        uint winnerIndex = pseudoRandom() % players.length;
        players[winnerIndex].transfer(address(this).balance);

        players = new address[](0);
    }
    modifier managerOnly() {
        require(msg.sender == manager);
        _;
    }
    function getPlayers() public view returns (address[]) {
        return players;
    }
}