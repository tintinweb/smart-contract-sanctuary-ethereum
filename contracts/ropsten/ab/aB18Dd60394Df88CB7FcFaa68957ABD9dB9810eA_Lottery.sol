//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Lottery {
  address payable[] public players;
  address public manager;

  event lotteryWinner(address _lotteryWinner);
  event lotteryManagerFee(uint256 _managerFee);
  event lotteryWinnerPrize(uint256 _winnerPrize);

  constructor() {
    manager = msg.sender;
  }

  receive() external payable {
    require(msg.sender != manager, "The manager can not participate in the lottery!");
    require(msg.value == 0.1 ether, "Not enough funds!");

    players.push(payable(msg.sender));
  }

  function random() public view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
  }

  function pickWinner() public {
    if (players.length < 7) require(msg.sender == manager, "You are not manager!");
    require(players.length >= 3, "Not enough players to finish lottery!");

    uint256 r = random();
    address payable winner;
    uint256 index = r % players.length;
    uint256 managerFee = (getBalance() * 10) / 100;
    uint256 winnerPrize = (getBalance() * 90) / 100;

    payable(manager).transfer(managerFee);
    emit lotteryManagerFee(managerFee);

    winner = players[index];
    winner.transfer(winnerPrize);
    emit lotteryWinnerPrize(winnerPrize);

    players = new address payable[](0);

    emit lotteryWinner(winner);
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getTotalPlayers() public view returns (uint256) {
    return players.length;
  }
}