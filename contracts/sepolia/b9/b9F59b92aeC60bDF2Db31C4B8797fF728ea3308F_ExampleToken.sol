pragma solidity 0.6.6;
import './StandardToken.sol';

contract ExampleToken is StandardToken {
  string public name = "ExampleToken"; 
  string public symbol = "EXT";
  uint public decimals = 18;
  uint public INITIAL_SUPPLY = 10000 * (10 ** decimals);
  uint256 public totalSupply;

  constructor() public   {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}