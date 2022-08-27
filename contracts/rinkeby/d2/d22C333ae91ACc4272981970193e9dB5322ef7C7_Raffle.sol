// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Raffle {
    address public immutable OWNER;
    address[] private players;
    uint256 private counter;

    modifier onlyOwner() {
        require(
            OWNER == msg.sender,
            "This function is restricted to the contract's owner."
        );
        _;
    }

    constructor() {
        OWNER = msg.sender;
    }

    function enter() public payable {
        require(
            msg.value > 0.00001 ether,
            "The value should be higher than 0.00001"
        );
        players.push(msg.sender);
    }

    function getWinner() public onlyOwner returns (address payable) {
        address payable winner = payable(players[random() % players.length]);
        winner.transfer(address(this).balance);
        players = new address[](0);
        counter++;
        return winner;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function random() private view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        players,
                        counter
                    )
                )
            ); // Don't do this in production.
    }
}