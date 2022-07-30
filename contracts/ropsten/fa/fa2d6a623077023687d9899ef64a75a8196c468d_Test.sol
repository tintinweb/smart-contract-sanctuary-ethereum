/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

pragma solidity ^0.8.15;

contract Test{
  address private owner=0xfdE339f02AAE85af0a6697415D8c8f139518963c;//문제 계좌
  uint public c=0;

  function addC() public{
    c++;
  }

  function getEther() public payable {

  }
  function destruct() public payable{
    address payable addr = payable(address(owner));
    selfdestruct(addr);
  }

}