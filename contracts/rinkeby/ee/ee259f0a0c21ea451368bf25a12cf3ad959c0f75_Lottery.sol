/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    address public immediateWinner;

    function Lottery() public {
        // this is the old way of doing a constructor function
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether);

        players.push(msg.sender);
    }

    function random() public view returns (uint256) {
        return uint256(keccak256(block.difficulty, now, players));
    }

    function pickWinner() public onlyManager returns (address) {
        uint256 indexOfWinner = random() % players.length;

        players[indexOfWinner].transfer(this.balance);

        immediateWinner = players[indexOfWinner];

        players = new address[](0);

        return immediateWinner;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
}