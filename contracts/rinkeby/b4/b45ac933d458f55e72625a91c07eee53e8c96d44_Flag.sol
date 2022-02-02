/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

pragma solidity ^0.6.0;

contract Flag {
  string public flag='katagaitai-CTF{ItIsEasyIfYouCanSeeTheExplorer}';

  constructor() public {
  }
  function getFlag() public view returns(string memory){
      return flag;
  }
}