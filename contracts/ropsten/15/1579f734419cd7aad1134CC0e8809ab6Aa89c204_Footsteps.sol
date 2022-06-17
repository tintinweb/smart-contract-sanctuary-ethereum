/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// @notice: Interface of Verifying contract
interface Iverifier{
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[2] memory input
        ) external view returns (bool);
}

abstract contract LoogiesContract {
  function tokenURI(uint256 id) external virtual view returns (string memory);
  function ownerOf(uint256 id) external virtual view returns (address);
}

contract Footsteps {
  mapping(address =>uint) public  bal;

  LoogiesContract public loogiescontract;
  address public verifier;
  struct Block{
      uint position;  
  }

  uint public constant height = 10;
  uint public constant width = 10;

  error AlreadyRegistered(address player);
  error InvalidProof();

  Block[width][height] public Area;

  struct Player{
    address player;
    uint health;
    uint location;
    uint zone;
  }

  Player[] public players;
  mapping(address =>uint) public loogies;

  constructor (address _verifier) public payable{
    // loogiescontract = LoogiesContract(_loogiescontract);
    _verifier = verifier;
  }

  
/* @notice: Register a player


**/

  function Register(uint LoogieId,uint[2] memory a,uint[2][2] memory b,uint[2] memory c,uint[2] memory input) external {
    require(Iverifier(verifier).verifyProof(a,b,c,input) == true,"Invalid input");

    Player memory  player = Player({
      player: msg.sender,
      health: 100,
      location: input[0],
      zone: input[1]
    });

    players.push(player);
    loogies[msg.sender] = LoogieId;
  }

  function getpayment() external payable {
    bal[msg.sender] += msg.value;
  }
}