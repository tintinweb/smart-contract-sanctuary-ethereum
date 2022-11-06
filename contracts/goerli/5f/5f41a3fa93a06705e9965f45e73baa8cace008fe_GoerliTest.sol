/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract GoerliTest {

  string public answer = "Works on goerli";

  function _showAnswer() public view returns(string memory){
    return answer;
  }

}