/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

pragma solidity ^0.5.16;

contract Bakery {

  // index of created contracts

  address[] public contracts;

  // useful to know the row count in contracts index

  function getContractCount() 
    public
    view
    returns(uint contractCount)
  {
    return contracts.length;
  }

  // deploy a new contract

  function newCookie()
    public
    returns(address newContract)
  {
    Cookie c = new Cookie();
    newContract = address(c);
    contracts.push(newContract);
  }
}


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