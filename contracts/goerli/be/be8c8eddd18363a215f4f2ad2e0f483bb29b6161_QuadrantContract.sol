/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

struct Card {
    string id;
    string expirationDate;
    string[] categories; 
}

contract QuadrantContract {
  address public owner = msg.sender;
  mapping(string => Card) public cards;

  constructor() {
  }

  modifier ownerOnly() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function addCard(Card memory card) 
    public  
    ownerOnly 
  {
    cards[card.id] = card;
  }

  function removeCard(string memory cardId) 
    public  
    ownerOnly 
  {
    delete cards[cardId];
  }
}