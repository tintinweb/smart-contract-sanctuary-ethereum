// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

import "./PausableToken.sol";

contract WETEST is PausableToken {
    string public name;
    string public symbol;
    uint public decimals;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

	
    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, address tokenOwner) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }
	
	function burn(uint256 _value) public {
		_burn(msg.sender, _value);
	}

	function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);
		balances[_who] = balances[_who].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}

    function mint(address account, uint256 amount) onlyOwner public {

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }    
}