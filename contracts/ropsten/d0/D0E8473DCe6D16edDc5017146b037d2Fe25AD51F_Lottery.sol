//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Lottery {
  address payable[] players;
  address lotteryManager;

  uint256 lotteryId;
  mapping(uint256 => address) lotteryHistory;

  event lotteryEnter(address _playerAddress, uint256 _amount);
  event lotteryWinner(address _lotteryWinner);
  event lotteryManagerFee(uint256 _managerFee);
  event lotteryWinnerPrize(uint256 _winnerPrize);

  constructor() {
    lotteryManager = msg.sender;
  }

  function enterLottery() public payable {
    require(msg.sender != lotteryManager, "The manager can not participate in the lottery!");
    require(msg.value == 0.1 ether, "Not enough funds!");

    players.push(payable(msg.sender));
    emit lotteryEnter(msg.sender, msg.value);
  }

  function pickWinner() public {
    require(players.length >= 3, "Not enough players to finish lottery!");
    if (players.length < 10) require(msg.sender == lotteryManager, "You are not manager!");
    else {
      if (msg.sender != lotteryManager) {
        address playerAddress;
        for (uint256 i = 0; i < players.length; i++) {
          if (players[i] == msg.sender) playerAddress = players[i];
        }
        require(playerAddress == msg.sender, "You are not participate in the lottery!");
      }
    }

    uint256 r = random();
    address payable winner;
    uint256 index = r % players.length;
    uint256 managerFee = (getBalance() * 10) / 100;
    uint256 winnerPrize = (getBalance() * 90) / 100;

    payable(lotteryManager).transfer(managerFee);
    emit lotteryManagerFee(managerFee);

    winner = players[index];
    emit lotteryWinner(winner);
    winner.transfer(winnerPrize);
    emit lotteryWinnerPrize(winnerPrize);

    lotteryHistory[lotteryId] = winner;
    lotteryId++;

    players = new address payable[](0);
  }

  function random() private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
  }

  receive() external payable {
    require(msg.sender != lotteryManager, "The manager can not participate in the lottery!");
    require(msg.value == 0.1 ether, "Not enough funds!");

    players.push(payable(msg.sender));
  }

  function getLotteryManager() public view returns (address) {
    return lotteryManager;
  }

  function getLotteryWinner(uint256 _index) public view returns (address) {
    return lotteryHistory[_index];
  }

  function getPlayers() public view returns (address payable[] memory) {
    return players;
  }

  function getPlayer(uint256 _index) public view returns (address) {
    return players[_index];
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getTotalPlayers() public view returns (uint256) {
    return players.length;
  }
}