//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CasinoOp {
  struct ProposedBet {
    address sideA;
    uint hashA;
    uint randomA;
    uint value;
    uint placedAt;
  }

  struct AcceptedBet {
    address sideB;
    uint hashB;
    uint randomB;
    uint acceptedAt;
  }

  mapping(uint => ProposedBet) public proposedBet;
  mapping(uint => AcceptedBet) public acceptedBet;

  function proposeBet(uint _commitment, uint _hashA) external payable {
    require(proposedBet[_commitment].value == 0,
      "there is already a bet on that commitment");
    require(msg.value > 0,
      "you need to actually bet something");

    proposedBet[_commitment].sideA = msg.sender;
    proposedBet[_commitment].hashA = _hashA;
    proposedBet[_commitment].value = msg.value;
    proposedBet[_commitment].placedAt = block.timestamp;
  }

  function acceptBet(uint _commitment, uint _hashB) external payable{
    require(acceptedBet[_commitment].hashB == 0,
      "there is already a bet on that commitment");
    require(proposedBet[_commitment].value > 0,
      "there is no bet on that commitment");
    require(proposedBet[_commitment].value == msg.value,
      "you need to bet the same amount as the other side");

    acceptedBet[_commitment].sideB = msg.sender;
    acceptedBet[_commitment].hashB = _hashB;
    acceptedBet[_commitment].acceptedAt = block.timestamp;
  }

  function settleBet(uint _commitment) internal {
    uint randomA = proposedBet[_commitment].randomA;
    uint randomB = acceptedBet[_commitment].randomB;
  
    if (randomA ^ randomB % 2 == 0) {
      // A wins
      payable(proposedBet[_commitment].sideA).transfer(proposedBet[_commitment].value);
    } else {
      // B wins
      payable(acceptedBet[_commitment].sideB).transfer(proposedBet[_commitment].value);
    }
  }

  function revealA(uint _commitment, uint randomA) external {
    require(proposedBet[_commitment].hashA > 0,
      "there is no bet on that commitment");
    require(acceptedBet[_commitment].hashB > 0,
      "there is no accepted on that commitment");

    uint hashA = uint(keccak256(abi.encodePacked(randomA)));
    require(hashA == proposedBet[_commitment].hashA,
      "the random number does not match the hash");
    proposedBet[_commitment].randomA = randomA;

    if(acceptedBet[_commitment].randomB > 0) {
      settleBet(_commitment);
    }
  }

  function revealB(uint _commitment, uint randomB) external {
    require(proposedBet[_commitment].hashA > 0,
      "there is no bet on that commitment");
    require(acceptedBet[_commitment].hashB > 0,
      "there is no accepted on that commitment");

    uint hashB = uint(keccak256(abi.encodePacked(randomB)));
    require(hashB == acceptedBet[_commitment].hashB,
      "the random number does not match the hash");
    acceptedBet[_commitment].randomB = randomB;

    if(proposedBet[_commitment].randomA > 0) {
      settleBet(_commitment);
    }
  }
}