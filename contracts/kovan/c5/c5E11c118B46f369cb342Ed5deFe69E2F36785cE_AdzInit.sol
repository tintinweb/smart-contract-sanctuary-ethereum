/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract AdzInit {

  address public owner;
  string public message;
  bool public saleIsActive;
  uint256 public constant MAX_PER_TX = 10;
  uint256 public price = 32320000000000000;

  constructor(string memory _message) {
    message = _message;
    saleIsActive=false;
    owner = msg.sender;
  }

  function hello() public view returns (string memory){
    return message;
  }

  function setMessage(string memory _message) public {
    message=_message;
  }

  function activateSale() public {
    saleIsActive=!saleIsActive;
  }

  //*** MINT */
  function pay(uint256 numberOfTokens)public payable {
    require(saleIsActive, "Sale must be active to mint");
    require(numberOfTokens <= MAX_PER_TX,"Max of 10 tokens per transaction");
    require((price*numberOfTokens) <= msg.value,"Ether value sent is not correct");
    message="payment ok";
  }
}