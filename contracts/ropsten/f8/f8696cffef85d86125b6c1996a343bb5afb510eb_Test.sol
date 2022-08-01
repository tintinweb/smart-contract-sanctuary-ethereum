/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

pragma solidity 0.4.24;

contract Test{
  address private owner=0x519E9B65145497fC7c2024a73897cf119281c7a9;//문제 계좌
  uint public c=0;

  function addC() public{
    c++;
  }

  function getEther() payable{

  }
  function destruct() public payable{
    selfdestruct(owner);
  }

}