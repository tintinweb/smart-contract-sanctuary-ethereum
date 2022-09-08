/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

pragma solidity ^0.8.16;

contract Lottery {
    address public Admin;
    address payable[] public players;

    constructor() {
        Admin = msg.sender;
    }

    // Only manager block
    modifier restricted() {
        require(msg.sender == Admin, "You are not the owner");
        _;
    }

    function enter() public payable {
        require(msg.value == .001 ether);
        players.push(payable(msg.sender));
    }

    //Pick a winning address based on a sudo-random hash converted to initergers.
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(block.difficulty, block.timestamp, players)
                )
            );
    }

    //pickWinner() picks the winning address, Only manager can call this function. After each round the player array is reset to 0.
    function pickWinner() public restricted {
        uint256 index = random() % players.length;
        uint256 balance = address(this).balance;
        payable(0x9e4A358854fE92d9bf17af6672503c38C52561D5).transfer(
            (balance * 5) / 100
        );
        players[index].transfer((balance * 95) / 100);
        delete players;
    }

    //Return all the players who entered.
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}