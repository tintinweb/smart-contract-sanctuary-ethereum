/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address payable[] public players;
    address immutable public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {

        // User must send 0.1ETH min, 100000000000000000 wei
        // Require doesn't consume gas because there's no code before it
        require(msg.value == 0.1 ether);

        // Convert plain address to payable one
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns (uint) {
        // On]y ownew can read the balance
        require(msg.sender == owner);
        return address(this).balance;
    }

    function getRandom() public view returns (uint) {
        // Get a real random num: https://docs.chain.link/docs/get-a-random-number/
        return uint(keccak256(abi.encodePacked(
            // Current block difficulty
            block.difficulty,
            block.timestamp,
            players.length
            )));
    }

    function pickWinner() public {
        require(msg.sender == owner);
        require(players.length >= 3);

        uint r = getRandom();
        address payable winner;

        uint index = r % players.length;
        winner = players[index];
        winner.transfer(getBalance());
        reset();
    }

    function reset() public {
        require(msg.sender == owner);
        // (0) size of the new dynamic array
        players = new address payable[](0);
    }
}