/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Counter{
  uint public count; // dichiarandola come pubblica, la potrò leggere;
  
  // funzioni per incrementare/decrementare
  // external -> verrà invocata dall'esterno
  // non è nè read nè pure perchè scrivo informazioni sulla blockchain
  // non ritorna nulla
  function inc() external {
    count += 1; // equivale a count = count + 1;
  }
  
  function dec() external {
    count -= 1;
  }
}