/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
  address payable[] public players;
  address payable public immutable owner;
  uint256 public playersCount;
  uint256 public immutable minPlayers;
  address[] public winners;
  uint256 public winnersCount;

  constructor() {
    owner = payable(msg.sender);
    playersCount = 0;
    minPlayers = 3;
  }

  receive() external payable {
    require(msg.sender != owner);
    // User must send 0.1ETH min, 100000000000000000 wei
    // Require doesn't consume gas because there's no code before it
    require(msg.value == 0.1 ether);

    // Convert plain address to payable one
    players.push(payable(msg.sender));
    playersCount++;
  }

  function getBalance() public view returns (uint256) {
    // On]y ownew can read the balance
    require(msg.sender == owner);
    return address(this).balance;
  }

  function getRandom() public view returns (uint256) {
    // Get a real random num: https://docs.chain.link/docs/get-a-random-number/
    return
      uint256(
        keccak256(
          abi.encodePacked(
            // Current block difficulty
            block.difficulty,
            block.timestamp,
            players.length
          )
        )
      );
  }

  function pickWinner() public {
    require(msg.sender == owner);
    require(players.length >= minPlayers);

    uint256 r = getRandom();
    address payable winner;

    uint256 index = r % players.length;
    winner = players[index];

    // Transfer 10% to the owner ;)
    owner.transfer(getBalance() / 10);

    // Transfer the rest of the balance to the winner
    winner.transfer(getBalance());
    winners.push(winner);
    winnersCount++;
    reset();
  }

  function reset() public {
    require(msg.sender == owner);
    // (0) size of the new dynamic array
    players = new address payable[](0);
    playersCount = 0;
  }
}