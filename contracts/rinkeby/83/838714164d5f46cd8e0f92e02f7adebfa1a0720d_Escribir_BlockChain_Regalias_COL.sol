/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 <0.8.0;


// SPDX-Licence-Identifier: MIT

pragma solidity >= 0.7.0 <0.8.0;

contract Escribir_BlockChain_Regalias_COL {
  string OperadorOil;

  function Escribir(string calldata _OperadorOil) public{
       OperadorOil = _OperadorOil;
  }
  
  function Leer() public view returns(string memory){
      return OperadorOil;
  }
}