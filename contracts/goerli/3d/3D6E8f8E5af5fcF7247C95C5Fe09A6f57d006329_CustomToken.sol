// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";

contract CustomToken is ERC20Mintable, ERC20Burnable {
	constructor(string memory name, string memory symbol, uint8 decimals, uint256 initialSupply) ERC20(name, symbol, decimals) {
		_setRole(msg.sender, ROLE_ADMIN, true);
		_setRole(msg.sender, ROLE_MINTER, true);
		_mint(msg.sender, initialSupply);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

abstract contract ERC20 {
	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Approval(address indexed owner, address indexed spender, uint256 amount);

	string public name ;
	string public symbol;
	uint8 immutable public decimals;
	uint256 public totalSupply;

	error InsufficientBalance(address from, uint256 available, uint256 required);
	error InsufficientAllowance(address owner, address spender, uint256 available, uint256 required);

	constructor(string memory _name, string memory _symbol, uint8 _decimals) {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
	}

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	function transfer(address to, uint256 amount) external returns (bool) {
		return _transfer(msg.sender, to, amount);
	}

	function transferFrom(address from, address to, uint256 amount) external returns (bool) {
		return _transfer(from, to, amount);
	}

	function approve(address spender, uint256 amount) external returns (bool) {
		allowance[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function _transfer(address from, address to, uint256 amount) private returns (bool) {
		if (from != msg.sender) {
			_decreaseAllowance(from, msg.sender, amount);
		}

		_decreaseBalance(from, amount);
		balanceOf[to] += amount;
		emit Transfer(from, to, amount);
		return true;
	}

	function _decreaseAllowance(address owner, address spender, uint256 amount) private {
		uint256 _allowance = allowance[owner][spender];
		if (_allowance < amount) {
			revert InsufficientAllowance(owner, spender, _allowance, amount);
		}
		unchecked {
			allowance[owner][spender] -= amount;
		}
		emit Approval(owner, spender, _allowance - amount);
	}

	function _decreaseBalance(address owner, uint256 amount) private {
		uint256 _balance = balanceOf[owner];
		if (_balance < amount) {
			revert InsufficientBalance(owner, _balance, amount);
		}
		unchecked {
			balanceOf[owner] -= amount;
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./ERC20.sol";

abstract contract ERC20Burnable is ERC20 {
	function burn(uint256 amount) external {
		uint256 _balance = balanceOf[msg.sender];
		if (_balance < amount) {
			revert InsufficientBalance(msg.sender, _balance, amount);
		}
		unchecked {
			balanceOf[msg.sender] -= amount;	
		}

		totalSupply -= amount;
		emit Transfer(msg.sender, address(0), amount);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./RoleBased.sol";
import "./ERC20.sol";

abstract contract ERC20Mintable is RoleBased, ERC20 {
	bytes32 constant public ROLE_MINTER = keccak256("ROLE_MINTER");

	function mint(uint256 amount) external onlyRole(ROLE_MINTER) {
		_mint(msg.sender, amount);
	}

	function _mint(address to, uint256 amount) internal {
		balanceOf[to] += amount;
		totalSupply += amount;
		emit Transfer(address(0), to, amount);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

abstract contract RoleBased {
	event RoleSet(address indexed user, bytes32 indexed role, bool isEnabled);

	bytes32 constant public ROLE_ADMIN = keccak256("ROLE_ADMIN");
	mapping (address => mapping (bytes32 => bool)) public roles;

	error Unauthorized(address user, bytes32 requiredRole);

	modifier onlyRole(bytes32 role) {
		if (roles[msg.sender][role] == false) {
			revert Unauthorized(msg.sender, role);
		}
		_;
	}

	function setRole(address user, bytes32 role, bool isEnabled) external onlyRole(ROLE_ADMIN) {
		_setRole(user, role, isEnabled);
	}

	function _setRole(address user, bytes32 role, bool isEnabled) internal {
		roles[user][role] = isEnabled;
		emit RoleSet(user, role, isEnabled);
	}
}