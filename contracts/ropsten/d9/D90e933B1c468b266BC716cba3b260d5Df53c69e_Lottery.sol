/**
 *Submitted for verification at Etherscan.io on 2020-08-25
*/

pragma solidity 0.5.12;

import './AddrArrayLib.sol';

contract Lottery {
    using AddrArrayLib for AddrArrayLib.Addresses;
    AddrArrayLib.Addresses managers;
    address public creator;
    address payable[] public players;

    event PlayerEntered(address indexed player, uint256 value);
    event WinnerPicked(address indexed winner);

    constructor() public {
        managers.pushAddress(msg.sender);
        creator = msg.sender;
    }

    modifier restricted() {
        //require(msg.sender == manager, "only contract creator allowed");
        require(managers.exists(msg.sender), "only managers allowed");
        _;
    }

    function () external payable {
        require(msg.value > .0000001 ether, "must pay the minimum amount");
        require(players.length < 50, "maximally 50 players");
        emit PlayerEntered(msg.sender, msg.value);
        players.push(msg.sender);
    }

    // This RNG is not secure, for demonstration purposes only
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted  returns (address) {
        uint index = random() % players.length;
        address payable winner = players[index];
        players = new address payable[](0);
        emit WinnerPicked(winner);
        winner.transfer(address(this).balance);
        return winner;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function addManager(address newManager) public restricted {
        managers.pushAddress(newManager);
    }
    function removeManager(address manager) public restricted {
        require(manager != creator, "creatpor cannot be removed.");
        managers.removeAddress(manager);
    }

       function getManagers() public view returns (address[] memory) {
        return managers.getAllAddresses();
    }

}