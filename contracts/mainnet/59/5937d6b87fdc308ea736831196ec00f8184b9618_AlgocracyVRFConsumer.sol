// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./iAlgocracyVRFConsumer.sol";

interface iLink {
  function transfer(address, uint256) external;
  function transferAndCall(address, uint256, bytes memory) external;
}

/// @title Algocracy VRF Consumer
/// @author jolan.eth

contract AlgocracyVRFConsumer {
  iLink public Link;
  iAlgocracyVRFConsumer public DAO;
  iAlgocracyVRFConsumer public Coordinator;

  bool public LOCK;
  bytes32 public KEYHASH;
  uint64 public SUBSCRIPTION;

  constructor(
    address _DAO,
    address _Link,
    address _Coordinator,
    bytes32 _KEYHASH
  ) {
    Link = iLink(_Link);
    DAO = iAlgocracyVRFConsumer(_DAO);
    Coordinator = iAlgocracyVRFConsumer(_Coordinator);
    
    KEYHASH = _KEYHASH;
    SUBSCRIPTION = Coordinator.createSubscription();
    Coordinator.addConsumer(SUBSCRIPTION, address(this));
  }

  function provideLINK(uint256 amount)
  public {
    Link.transferAndCall(address(Coordinator), amount, abi.encode(SUBSCRIPTION));
  }

  function withdrawLINK(uint256 amount)
  public {
    iAlgocracyVRFConsumer PassNFT = iAlgocracyVRFConsumer(DAO.PassNFT());

    require(
      PassNFT.getAccessLevel(PassNFT.ownedBy(msg.sender)) == PassNFT.ACCESS_LEVEL_CORE(),
      "AlgocracyVRFCC0nSUMMER::withdrawLINK() - msg.sender does not have access level"
    );

    Link.transfer(msg.sender, amount);
  }

  function requestRandomWords()
  public {
    iAlgocracyVRFConsumer PassNFT = iAlgocracyVRFConsumer(DAO.PassNFT());
    iAlgocracyVRFConsumer RandomNFT = iAlgocracyVRFConsumer(DAO.RandomNFT());

    require(
      !LOCK,
      "AlgocracyVRFCC0nSUMMER::requestRandomWords() - function is LOCK, please wait fulfillment"
    );

    require(
      PassNFT.getAccessLevel(PassNFT.ownedBy(msg.sender)) == PassNFT.ACCESS_LEVEL_CORE() ||
      PassNFT.getAccessLevel(PassNFT.ownedBy(msg.sender)) == PassNFT.ACCESS_LEVEL_OPERATOR(),
      "AlgocracyVRFCC0nSUMMER::requestRandomWords() - msg.sender does not have access level"
    );

    uint16 tic = RandomNFT.FIXED_TIC();
    uint32 gasLimit = RandomNFT.FIXED_GAS();
    uint32 quantity = RandomNFT.FIXED_QTY();
    Coordinator.requestRandomWords(
      KEYHASH,
      SUBSCRIPTION,
      tic,
      gasLimit,
      quantity
    );

    LOCK = true;
  }

  function fulfillRandomWords(uint256 id, uint256[] memory provableRandom)
  internal {
    iAlgocracyVRFConsumer RandomNFT = iAlgocracyVRFConsumer(DAO.RandomNFT());
    RandomNFT.mintRandom(id, provableRandom[0]);
    LOCK = false;
  }

  function rawFulfillRandomWords(uint256 id, uint256[] memory provableRandom) external {
    require(
      address(Coordinator) == msg.sender,
      "AlgocracyVRFCC0nSUMMER::rawFulFillRandomWords() - msg.sender is not Coordinator"
    );

    fulfillRandomWords(id, provableRandom);
  }
}