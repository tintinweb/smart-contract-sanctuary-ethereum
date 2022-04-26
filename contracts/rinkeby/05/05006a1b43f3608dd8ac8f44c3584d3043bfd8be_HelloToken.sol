pragma solidity ^0.4.19;
import "./StandardToken.sol";

contract HelloToken is ERC20 {
  string public name = "HelloCoin";
  string public symbol = "[email protected]";
  uint8 public decimals = 2;
  uint256 public INITIAL_SUPPLY = 88888;

  function HelloToken() public {
    _totalSupply = INITIAL_SUPPLY;
    _balances[msg.sender] = INITIAL_SUPPLY;
  }
}