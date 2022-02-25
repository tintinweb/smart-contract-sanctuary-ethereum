/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library SafeMathInt {
	int256 private constant MIN_INT256 = int256(1) << 255;
	int256 private constant MAX_INT256 = ~(int256(1) << 255);

	function mul(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a * b;

		require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
		require((b == 0) || (c / b == a));
		return c;
	}

	function div(int256 a, int256 b) internal pure returns (int256) {
		require(b != -1 || a != MIN_INT256);

		return a / b;
	}

	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a));
		return c;
	}

	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	}

	function abs(int256 a) internal pure returns (int256) {
		require(a != MIN_INT256);
		return a < 0 ? -a : a;
	}
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, 'SafeMath: addition overflow');

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, 'SafeMath: subtraction overflow');
	}

	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, 'SafeMath: multiplication overflow');

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, 'SafeMath: division by zero');
	}

	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

interface InterfaceLP {
	function sync() external;
}

library Roles {
	struct Role {
		mapping(address => bool) bearer;
	}

	/**
	 * @dev Give an account access to this role.
	 */
	function add(Role storage role, address account) internal {
		require(!has(role, account), 'Roles: account already has role');
		role.bearer[account] = true;
	}

	/**
	 * @dev Remove an account's access to this role.
	 */
	function remove(Role storage role, address account) internal {
		require(has(role, account), 'Roles: account does not have role');
		role.bearer[account] = false;
	}

	/**
	 * @dev Check if an account has this role.
	 * @return bool
	 */
	function has(Role storage role, address account) internal view returns (bool) {
		require(account != address(0), 'Roles: account is the zero address');
		return role.bearer[account];
	}
}

contract MinterRole {
	using Roles for Roles.Role;

	event MinterAdded(address indexed account);
	event MinterRemoved(address indexed account);

	Roles.Role private _minters;

	constructor() {
		_addMinter(msg.sender);
	}

	modifier onlyMinter() {
		require(isMinter(msg.sender), 'MinterRole: caller does not have the Minter role');
		_;
	}

	function isMinter(address account) public view returns (bool) {
		return _minters.has(account);
	}

	function renounceMinter() public {
		_removeMinter(msg.sender);
	}

	function _addMinter(address account) internal {
		_minters.add(account);
		emit MinterAdded(account);
	}

	function _removeMinter(address account) internal {
		_minters.remove(account);
		emit MinterRemoved(account);
	}
}

abstract contract ERC20Detailed is IERC20 {
	string private _name;
	string private _symbol;
	uint8 private _decimals;

	constructor(
		string memory name_,
		string memory symbol_,
		uint8 decimals_
	) {
		_name = name_;
		_symbol = symbol_;
		_decimals = decimals_;
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}
}

interface IDEXRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountETH,
			uint256 liquidity
		);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

interface IDEXFactory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Ownable {
	address private _owner;

	event OwnershipRenounced(address indexed previousOwner);

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		_owner = msg.sender;
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(isOwner());
		_;
	}

	function isOwner() public view returns (bool) {
		return msg.sender == _owner;
	}

	function renounceOwnership() public onlyOwner {
		emit OwnershipRenounced(_owner);
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0));
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract Test is IERC20, ERC20Detailed, Ownable {
	using SafeMath for uint256;

	uint256 private constant DECIMALS = 18;
	uint256 private constant MAX_SUPPLY = ~uint128(0);
	uint256 private constant INITIAL_SUPPLY = 100 ether; // количество токенов

	mapping(address => mapping(address => uint256)) private _allowed;

	mapping(address => uint256) private _balances;

	uint256 private _totalSupply;

	uint256 public userCounter;
	mapping(uint256 => address) public users;

	mapping(address => uint256) private _timestamps;

	uint256 public timeDelay = 30 minutes; // каждые 30 минут

	uint256 public percentages = 10; // 0.01% прибавления

	uint256 private TAX_FEE = 5000; // 5% комиссии с каждого перевода

	uint256 public pool;

	constructor() ERC20Detailed('Test', 'TST', uint8(DECIMALS)) {
		_totalSupply = _totalSupply.add(INITIAL_SUPPLY);

		pool += INITIAL_SUPPLY;
	}

	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address who) public view override returns (uint256) {
		return _balances[who];
	}

	function allowance(address owner_, address spender) external view override returns (uint256) {
		return _allowed[owner_][spender];
	}

	function approve(address spender, uint256 value) external override returns (bool) {
		_allowed[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	function transfer(address to, uint256 value) external override returns (bool) {
		uint256 amountFee = (value * TAX_FEE) / 100000;

		pool = pool.add(amountFee);

		_timestamps[msg.sender] = block.timestamp;
		_timestamps[to] = block.timestamp;

		_balances[msg.sender] = _balances[msg.sender].sub(amountFee);

		_transferFrom(msg.sender, to, value - amountFee);

		return true;
	}

	function _transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) internal returns (bool) {
		_balances[sender] = _balances[sender].sub(amount);

		_balances[recipient] = _balances[recipient].add(amount);

		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external override returns (bool) {
		if (_allowed[from][msg.sender] != type(uint256).max) {
			_allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value, 'Insufficient Allowance');
		}

		_transferFrom(from, to, value);
		return true;
	}

	function mint() public view onlyOwner returns (bool) {
		return true;
	}

	function buyToken() external payable returns (bool) {
		require(msg.value > 0);

		if (balanceOf(msg.sender) > 0) {
			pool = pool.sub(msg.value);
			_balances[msg.sender] = _balances[msg.sender].add(msg.value);

			return true;
		}

		userCounter = userCounter.add(1);

		pool = pool.sub(msg.value);
		_balances[msg.sender] = msg.value;

		_timestamps[msg.sender] = block.timestamp;

		users[userCounter] = msg.sender;

		return true;
	}

	function claim() external returns (bool) {
		require(block.timestamp - _timestamps[msg.sender] >= timeDelay);

		uint256 rewardCount = (block.timestamp.sub(_timestamps[msg.sender])).div(timeDelay);

		for (uint256 i = 1; i <= rewardCount; i++) {
			uint256 amount = getAmount(msg.sender);
			pool = pool.sub(amount);

			_balances[msg.sender] = _balances[msg.sender].add(amount);
		}

		_timestamps[msg.sender] = block.timestamp;

		return true;
	}

	function getAmount(address _user) private view returns (uint256) {
		uint256 balance = balanceOf(_user);

		uint256 amount = (balance.mul(percentages)).div(100000);

		return amount;
	}
}