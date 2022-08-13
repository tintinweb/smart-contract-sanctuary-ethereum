/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// File: ERC20.sol

pragma solidity ^0.4.18;

contract ERC20 {
  uint public totalSupply;

  event Transfer(address indexed from, address indexed to, uint value);  
  event Approval(address indexed owner, address indexed spender, uint value);

  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);  
}

// File: s7swap.sol

pragma solidity ^0.4.18;


contract S7SWAP {
    function check () public view returns (address msgSender) {
        return msg.sender;
    }
}