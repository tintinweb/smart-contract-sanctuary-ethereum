/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

contract Coin {
  address public minter;
  mapping (address => uint) private balances;

  event Sent(address from, address to, uint amount);

  constructor() public {
    minter = msg.sender;
  }

  function mint(address receiver, uint amount) public {
    require(msg.sender == minter,"Unauthorized operation !");
    require(amount < 1e60,"The maximum supply has been reached !");
    balances[receiver] += amount;
  }

  function send(address receiver, uint amount) public {
    require(amount <= balances[msg.sender], "Insufficient balance.");
    balances[msg.sender] -= amount;
    balances[receiver] += amount;
    emit Sent(msg.sender, receiver, amount);
  }
  
  function balanceOf(address tokenOwner) public view returns(uint balance){
    return balances[tokenOwner];
  }
}