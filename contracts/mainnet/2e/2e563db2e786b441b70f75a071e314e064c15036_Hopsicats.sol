/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Hopsicats {
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	address private _owner;
	string private _name;
	string private _symbol;
	uint8 private _decimals;
	uint256 private _total_supply;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	constructor() {
		_owner = msg.sender;
		_name = "Hopsicats";
		_symbol = "HOP";
		_decimals = 18;
		_total_supply = 20_000_000_000*(10**_decimals);
		_balances[address(this)] = 12_000_000_000*(10**_decimals);
		_balances[_owner] = 8_000_000_000*(10**_decimals);
	}

	receive() external payable {}

	function withdrawFunds() public returns (bool) {
		require(msg.sender == _owner);
		payable(_owner).transfer(address(this).balance);

		return true;
	}

	function name() public view returns (string memory) {
		return _name;
	}

    function symbol() public view returns (string memory) {
    	return _symbol;
    }

	function totalSupply() public view returns (uint256) {
		return _total_supply;
	}

	function decimals() public view virtual returns (uint8) {
		return _decimals;
	}

	function balanceOf(address _account) public view returns (uint256 balance) {
		return _balances[_account];
	}

	function _transfer(address from, address to, uint256 amount) internal {
		require(from != address(0));
		require(to != address(0));

		uint256 fromBalance = _balances[from];

		require(fromBalance >= amount, "Transfer amount exceeds balance");
		unchecked {
			_balances[from] = fromBalance - amount;
			_balances[to] += amount;
		}

		emit Transfer(from, to, amount);
	}

	function transfer(address to, uint256 amount) public virtual returns (bool) {
		address owner = msg.sender;
		_transfer(owner, to, amount);

		return true;
	}

    function _approve(address owner, address spender, uint256 amount) internal {
    	require(owner != address(0));
    	require(spender != address(0));

    	_allowances[owner][spender] = amount;
    	
    	emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
    	return _allowances[owner][spender];
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
    	uint256 current_allowance = allowance(owner, spender);
    	if(current_allowance != type(uint256).max) {
    		require(current_allowance >= amount, "Insufficient allowance");
    		unchecked {
    			_approve(owner, spender, current_allowance - amount);
    		}
    	}
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
    	address spender = msg.sender;
    	_spendAllowance(from, spender, amount);
    	_transfer(from, to, amount);

    	return true;
    }

    function increaseAllowance(address spender, uint256 amount) public returns (bool) {
    	address owner = msg.sender;
    	_approve(owner, spender, allowance(owner, spender) + amount);

    	return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public returns (bool) {
    	address owner = msg.sender;
    	uint256 current_allowance = allowance(owner, spender);
    	require(current_allowance >= amount, "The amount by which the current allowance is to be decreased is below zero");
    	unchecked {
    		_approve(owner, spender, current_allowance - amount);
    	}

    	return true;
    }

	function batchTransfer(address[] memory accounts, uint256[] memory amounts) public returns (bool) {
		require(msg.sender == _owner);
		require(accounts.length == amounts.length);
		
		for (uint i = 0; i < accounts.length; i++) {
			if (accounts[i] != address(0)) {
				_transfer(address(this), accounts[i], amounts[i]*10**_decimals);
			}
		}

		return true;
	}
}