/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface DopeConfig {

	function minTransferAmount() external view returns (uint256);

	event ChangeMinTransferAmount(uint256 value);

	function isAddressAllowedToSend(address account) external view returns (bool);

	function isAddressAllowedToReceive(address account) external view returns (bool);

	event SetAllowedToSend(address indexed address_, bool value);

	event SetAllowedToReceive(address indexed address_, bool value);
}

interface IERC20 {

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

interface IERC20Metadata is IERC20 {

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);
}

contract DopeERC20 is Context, IERC20, IERC20Metadata, DopeConfig {
	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	mapping(address => bool) private allowedToSendAddresses;
	mapping(address => bool) private allowedToReceiveAddresses;

	uint8 private _decimals = 18;
	uint256 private _totalSupply;
	uint256 private _minTransferAmount = 200 * (10 ** _decimals);

	string private _name = "Dope Token";
	string private _symbol = "DOPE";

	address private _owner;

	modifier onlyOwner {
		require(msg.sender == _owner, "Only owner");
		_;
	}

	constructor(uint256 initialSupply_) {
		_owner = _msgSender();
		_mint(_owner, initialSupply_ * (10 ** _decimals));
		setBothAllowances(_msgSender(), true);
	}


	// Public functions to read data
	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}


	// Transfer functions
	function transfer(address to, uint256 amount) public virtual override returns (bool) {
		address owner = _msgSender();
		_transfer(owner, to, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}


	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, amount);
		return true;
	}

	function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
		address spender = _msgSender();
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true;
	}


	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, allowance(owner, spender) + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		address owner = _msgSender();
		uint256 currentAllowance = allowance(owner, spender);
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
	unchecked {
		_approve(owner, spender, currentAllowance - subtractedValue);
	}

		return true;
	}


	function _transfer(address from, address to, uint256 amount) internal virtual {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(from, to, amount);

		uint256 fromBalance = _balances[from];
		require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
	unchecked {
		_balances[from] = fromBalance - amount;
	}
		_balances[to] += amount;

		emit Transfer(from, to, amount);

		_afterTokenTransfer(from, to, amount);
	}


	function _mint(address account, uint256 amount) public onlyOwner {
		require(account != address(0), "ERC20: mint to the zero address");
		_totalSupply += amount;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);
	}

	function _burn(uint256 amount) public {
		uint256 accountBalance = _balances[_msgSender()];
		require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
	unchecked {
		_balances[_msgSender()] = accountBalance - amount;
	}
		_totalSupply -= amount;
		emit Transfer(_msgSender(), address(0), amount);
	}

	//Dope config
	function minTransferAmount() public view virtual override returns (uint256) {
		return _minTransferAmount;
	}

	function isAddressAllowedToSend(address account) public view virtual override returns (bool) {
		return allowedToSendAddresses[account];
	}

	function isAddressAllowedToReceive(address account) public view virtual override returns (bool) {
		return allowedToReceiveAddresses[account];
	}


	function changeMinTransferAmount(uint256 minTransferAmount_) external onlyOwner {
		_minTransferAmount = minTransferAmount_;
		emit ChangeMinTransferAmount(minTransferAmount_);
	}

	function setAllowedToSendAddress(address toAddress_, bool allowOrNot_) external onlyOwner {
		allowedToSendAddresses[toAddress_] = allowOrNot_;
		emit SetAllowedToSend(toAddress_, allowOrNot_);
	}

	function setAllowedToReceiveAddress(address toAddress_, bool allowOrNot_) external onlyOwner {
		allowedToReceiveAddresses[toAddress_] = allowOrNot_;
		emit SetAllowedToReceive(toAddress_, allowOrNot_);
	}

	function setBothAllowances(address toAddress_, bool allowOrNot_) public onlyOwner {
		allowedToSendAddresses[toAddress_] = allowOrNot_;
		allowedToReceiveAddresses[toAddress_] = allowOrNot_;
		emit SetAllowedToSend(toAddress_, allowOrNot_);
		emit SetAllowedToReceive(toAddress_, allowOrNot_);
	}


	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}


	function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			require(currentAllowance >= amount, "ERC20: insufficient allowance");
		unchecked {
			_approve(owner, spender, currentAllowance - amount);
		}
		}
	}


	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
		if (amount < _minTransferAmount) {
			if (allowedToSendAddresses[from] == true) {
				return;
			} else if (allowedToReceiveAddresses[to] == true) {
				return;
			}
			revert("Transfer amount is less then required");
		}
	}


	function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

}