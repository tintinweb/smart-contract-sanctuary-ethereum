/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

struct RelayerState {
  uint256 balance;
  string ensName;
}

contract RelayerRegistry {
  address public tornadoRouter;
  uint256 public minStakeAmount;

  mapping(address => RelayerState) public relayers;
  mapping(address => address) public workers;

  function register(
    string calldata ensName,
    uint256 stake,
    address[] calldata workersToRegister
  ) external {
    address relayer = msg.sender;
    RelayerState storage metadata = relayers[relayer];

    require(workers[relayer] == address(0), "cant register again");

    metadata.balance = stake;
    metadata.ensName = ensName;
    workers[relayer] = relayer;

    for (uint256 i = 0; i < workersToRegister.length; i++) {
      address worker = workersToRegister[i];
      _registerWorker(relayer, worker);
    }
  }

  function _registerWorker(address relayer, address worker) internal {
    require(workers[worker] == address(0), "can't steal an address");
    workers[worker] = relayer;
  }

  function stakeToRelayer(address relayer, uint256 stake) external {
    require(workers[relayer] == relayer, "!registered");
    relayers[relayer].balance = stake + relayers[relayer].balance;
  }

  function isRelayer(address toResolve) external view returns (bool) {
    return workers[toResolve] != address(0);
  }

  function isRelayerRegistered(address relayer, address toResolve)
    external
    view
    returns (bool)
  {
    return workers[toResolve] == relayer;
  }

  function getRelayerEnsName(address relayer) external view returns (string memory) {
    return relayers[workers[relayer]].ensName;
  }

  function getRelayerBalance(address relayer) external view returns (uint256) {
    return relayers[workers[relayer]].balance;
  }
}