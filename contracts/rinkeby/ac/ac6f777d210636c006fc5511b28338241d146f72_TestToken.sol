pragma solidity ^0.4.19;
import "./ERC20.sol";

contract TestToken is ERC20 {
	string public name = "TestToken";
	string public symbol = "TEST";
	uint8 public decimals = 2;
	uint256 public INITIAL_SUPPLY = 88888;

	constructor() public {
		_mint(msg.sender, INITIAL_SUPPLY);
	}
	
	function mint() public {
		_mint(msg.sender, 800);
	}
}