/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Contador {
  int contador = 0;
  function incrementar() public {
    contador = contador + 1;
  }
  function decrementar() public {
    contador = contador - 1;
  }
}