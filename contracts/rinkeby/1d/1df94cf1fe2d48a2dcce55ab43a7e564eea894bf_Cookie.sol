/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

pragma solidity ^0.5.16;

contract Cookie {

  // suppose the deployed contract has a purpose

  function getFlavor()
    public
    pure
    returns (string memory)
  {
    return  "mmm ... chocolate chip";
  }    
}