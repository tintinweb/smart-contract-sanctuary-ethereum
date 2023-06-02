/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

/**
 * Deflationary with true burns and innovative reflects.
 * 2% burn 1% reflect 1% dev
 *
 * https://t.me/WFIREPORTAL
 * https://www.wildfire.finance/
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

interface IUniRouter {
	function WETH() external pure returns (address);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IPair {
	function sync() external;
}

abstract contract Ownership {

	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	error NoPermission();

	modifier onlyOwner {
		if (msg.sender != owner) {
			revert NoPermission();
		}
		_;
	}

	constructor(address owner_) {
		owner = owner_;
	}

	function _renounceOwnership() internal virtual {
		owner = address(0);
		emit OwnershipTransferred(owner, address(0));
	}

	function renounceOwnership() external onlyOwner {
		_renounceOwnership();
	}
}

contract Wildfire is Ownership {

	struct AccountStatus {
		uint224 baseBalance;
		bool cannotReflect;
		bool taxExempt;
		bool isBot;
		bool canBurn;
	}

	string private constant _name = "Wildfire";
	string private constant _symbol = "WFIRE";
	uint256 constant private _totalSupply = 100_000 ether;
	uint8 constant private _decimals = 18;
	address private constant DEAD = address(0xDEAD);
	address private immutable _launchManager;

	bool private _inSwap;
	bool public launched;
	bool public limited = true;
	uint8 private _buyTax = 30;
    uint8 private _saleTax = 30;
	uint8 private constant _absoluteMaxTax = 40;
	address private _pair;
	
	address private _router;

	uint128 private _totalSupplyForReflect;
	uint128 private _totalTokensReflected;

	uint128 private immutable _maxTx;
	uint128 private immutable _maxWallet;

	uint128 private _swapThreshold;
	uint128 private _swapAmount;

	uint32 private _lastBurn;
	uint32 private immutable _lburnTimeLimit = 1 days;
	uint192 private _maxDayBurn;

	mapping (address => AccountStatus) private _accStatus;
	mapping (address => mapping (address => uint256)) private _allowances;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Burning(uint256 timestamp, uint256 tokenAmount);

	error ExceedsAllowance();
	error ExceedsBalance();
	error ExceedsLimit();
	error NotTradeable();

	modifier swapping {
		_inSwap = true;
		_;
		_inSwap = false;
	}

	modifier onlyBurner {
		if (!_accStatus[msg.sender].canBurn) {
			revert NoPermission();
		}
		_;
	}

	constructor(address router) Ownership(msg.sender) {
		_router = router;
		_accStatus[msg.sender].baseBalance = uint224(_totalSupply);

		// Reflect config
		// _totalSupplyForReflect is not edited because deployer does not get reflects.
		_accStatus[msg.sender].cannotReflect = true;
		_accStatus[msg.sender].taxExempt = true;
		_accStatus[address(this)].cannotReflect = true;
		_accStatus[address(this)].taxExempt = true;
		_accStatus[router].cannotReflect = true;

		// Launch settings config
		_maxTx = uint128(_totalSupply / 100);
		_maxWallet = uint128(_totalSupply / 50);
		_swapThreshold = uint128(_totalSupply / 200);
		_swapAmount = uint128(_totalSupply / 200);
		_approve(address(this), router, type(uint256).max);
		_approve(msg.sender, router, type(uint256).max);
		_launchManager = msg.sender;

		// Burns config
		// Daily burn can only be done after 1 day has passed from deploy.
		_lastBurn = uint32(block.timestamp);
		_maxDayBurn = uint192(_totalSupply / 33);

		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	function name() external pure returns (string memory) {
		return _name;
	}

	function symbol() external pure returns (string memory) {
		return _symbol;
	}

	function decimals() external pure returns (uint8) {
		return _decimals;
	}

	function totalSupply() external pure returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) external view returns (uint256) {
		return _balanceOf(account);
	}

	function _balanceOf(address account) private view returns (uint256) {
		if (_accStatus[account].cannotReflect || _totalTokensReflected == 0) {
			return _baseBalanceOf(account);
		}
		return _baseBalanceOf(account) + _reflectsOf(account);
	}

	function _baseBalanceOf(address account) private view returns (uint256) {
		return _accStatus[account].baseBalance;
	}

	function reflectsOf(address account) external view returns (uint256) {
		return _reflectsOf(account);
	}

	function balanceDetailOf(address account) external view returns (uint256 baseBalance, uint256 reflectBalance) {
		baseBalance = _baseBalanceOf(account);
		reflectBalance = _reflectsOf(account);
	}

	function _reflectsOf(address account) private view returns (uint256) {
		if (_accStatus[account].cannotReflect) {
			return 0;
		}
		if (_totalTokensReflected == 0) {
			return 0;
		}
		uint256 baseBalance = _accStatus[account].baseBalance;
		if (baseBalance == 0) {
			return 0;
		}
		uint256 relation = 1 ether;
		return baseBalance * relation * _totalTokensReflected / relation / _totalSupplyForReflect;
	}

	function _addToBalance(address account, uint256 amount) private {
		unchecked {
			_accStatus[account].baseBalance += uint224(amount);
		}
		if (!_accStatus[account].cannotReflect) {
			unchecked {
				_totalSupplyForReflect += uint128(amount);
			}
		}
	}

	/**
	 * @dev Subtracts amount from balance and updates reflet values.
	 */
	function _subtractFromBalance(address account, uint256 amount) private {
		// Check if sender owns the correct balance.
		uint256 senderBalance = _balanceOf(account);
		if (senderBalance < amount) {
			revert ExceedsBalance();
		}

		// If cannot get reflect, entire balances on regular balance record.
		if (_accStatus[account].cannotReflect) {
			unchecked {
				_accStatus[account].baseBalance -= uint224(amount);
			}
			return;
		}

		// Take appropriate amount from reflected tokens.
		uint256 reflectTokensOwned = _reflectsOf(account);
		uint256 baseBalance = _accStatus[account].baseBalance;
		if (amount == senderBalance) {
			_totalTokensReflected -= uint128(amount - baseBalance);
			_totalSupplyForReflect -= uint128(baseBalance);
			_accStatus[account].baseBalance = 0;
		} else {
			uint256 relation = 1 ether;
			uint256 fromReflect = amount * relation * reflectTokensOwned / relation / baseBalance;
			uint256 fromBalance = amount - fromReflect;
			_accStatus[account].baseBalance = uint224(baseBalance - fromBalance);
			_totalTokensReflected -= uint128(fromReflect);
			_totalSupplyForReflect -= uint128(fromBalance);
		}
	}

	function transfer(address recipient, uint256 amount) external returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function allowance(address owner_, address spender) external view returns (uint256) {
		return _allowances[owner_][spender];
	}

	function approve(address spender, uint256 amount) external returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	function _approve(address owner_, address spender, uint256 amount) private {
		_allowances[owner_][spender] = amount;
		emit Approval(owner_, spender, amount);
	}

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][msg.sender];
		if (currentAllowance < amount) {
			revert ExceedsAllowance();
		}
		_approve(sender, msg.sender, currentAllowance - amount);

		return true;
	}

	function _beforeTokenTransfer(address sender, address recipient, uint256/* amount*/) private view {
		if (tx.origin != owner && (!launched || _accStatus[sender].isBot || _accStatus[recipient].isBot || _accStatus[tx.origin].isBot)) {
			revert NotTradeable();
		}
	}

	function _transfer(address sender, address recipient, uint256 amount) private {
		_beforeTokenTransfer(sender, recipient, amount);

		_subtractFromBalance(sender, amount);

		// Check whether to apply tax or not.
		uint256 amountReceived = amount;
		bool takeTax = !_accStatus[sender].taxExempt && !_accStatus[recipient].taxExempt;
		if (takeTax) {
			address tradingPair = _pair;
			bool isBuy = sender == tradingPair;
			bool isSale = recipient == tradingPair;

			if (isSale) {
				uint256 contractBalance = _balanceOf(address(this));
				if (contractBalance > 0) {
					if (!_inSwap && contractBalance >= _swapThreshold) {
						uint256 maxSwap = _swapAmount;
						uint256 toSwap = contractBalance > maxSwap ? maxSwap : contractBalance;
						_swap(toSwap);
						if (address(this).balance > 0) {
							launchFunds();
						}
					}
				}

				amountReceived = _takeTax(sender, amount, _saleTax);
			}

			if (isBuy) {
				amountReceived = _takeTax(sender, amount, _buyTax);
			}

			if (recipient != address(this)) {
				if (limited) {
					if (
						amountReceived > _maxTx
						|| (!isSale && _balanceOf(recipient) + amountReceived > _maxWallet)
					) {
						revert ExceedsLimit();
					}
				}
			}
		}

		_addToBalance(recipient, amountReceived);

		emit Transfer(sender, recipient, amountReceived);
	}

	function setIsBurner(address b, bool isb) external onlyOwner {
		_accStatus[b].canBurn = isb;
	}

	receive() external payable {}

	/**
	 * @dev Allow everyone to trade the token. To be called after liquidity is added.
	 */
	function allowTrading(address tradingPair) external onlyOwner {
		_pair = tradingPair;
		_setCannotReflect(tradingPair, true);
		launched = true;
	}

	function setTradingPair(address tradingPair) external onlyOwner {
		// Trading pair must always be ignored from reflects.
		// Otherwise, reflects slowly erode the price downwards.
		_pair = tradingPair;
		_setCannotReflect(tradingPair, true);
	}

	function setCannotReflect(address account, bool cannot) external onlyOwner {
		_setCannotReflect(account, cannot);
	}

	function _setCannotReflect(address account, bool cannot) private {
		if (_accStatus[account].cannotReflect == cannot) {
			return;
		}
		_accStatus[account].cannotReflect = cannot;
		if (cannot) {
			// Remove base balance from supply that gets reflects.
			unchecked {
				_totalSupplyForReflect -= uint128(_accStatus[account].baseBalance);
			}
		} else {
			// Add base balance to supply that gets reflects.
			unchecked {
				_totalSupplyForReflect += uint128(_accStatus[account].baseBalance);
			}
		}
	}

	function setRouter(address r) external onlyOwner {
		_router = r;
		_setCannotReflect(r, true);
	}

	function conflagration(uint256 amount) external onlyBurner {
		// Only once per day
		uint256 timePassed = block.timestamp - _lastBurn;
		if (timePassed < _lburnTimeLimit) {
			revert NoPermission();
		}

		// Check it doesn't go above token limits.
		address pair = _pair;
		uint256 maxBurnable = timePassed * _maxDayBurn / _lburnTimeLimit;
		if (amount > maxBurnable || _balanceOf(pair) <= amount) {
			revert NoPermission();
		}

		_subtractFromBalance(pair, amount);
		_addToBalance(DEAD, amount);

		IPair(pair).sync();

		emit Transfer(pair, DEAD, amount);
		emit Burning(block.timestamp, amount);
	}

	function _takeTax(address sender, uint256 amount, uint256 baseTax) private returns (uint256) {
		if (baseTax == 0) {
			return amount;
		}
		if (baseTax > _absoluteMaxTax) {
			baseTax = _absoluteMaxTax;
		}

		uint256 fee = amount * baseTax / 100;
		uint256 amountToReceive;
		unchecked {
			// Tax is capped so the fee can never be equal or more than amount.
			amountToReceive = amount - fee;
		}

		// During launch tax is given to token contract.
		if (owner != address(0)) {
			_addToBalance(address(this), fee);
			emit Transfer(sender, address(this), fee);
			return amountToReceive;
		}

		// After launch taxes.
		// 1/4 of tax is reflected, 2/4 is burnt, 1/4 is to cover dev costs.
		uint256 forReflectAndDev = fee / 4;
		uint256 forBurn = fee - (forReflectAndDev * 2);
		unchecked {
			_totalTokensReflected += uint128(forReflectAndDev);
		}
		_addToBalance(address(this), forReflectAndDev);
		_addToBalance(DEAD, forBurn);
		emit Burning(block.timestamp, forBurn);
		// This emit makes all transfer emits to be consistent with total supply.
		// forReflect is actually sent to everyone able to reflect, so it's not possible to emit transfers for those.
		// There's several solutions for reflect, none are elegant are the more consistent with transfers the more gas it uses.
		emit Transfer(sender, DEAD, fee - forReflectAndDev);
		emit Transfer(sender, address(this), forReflectAndDev);
		return amountToReceive;
	}

	function setUnlimited() external onlyOwner {
		limited = false;
	}

	function setBuyTax(uint8 buyTax) external onlyOwner {
		if (buyTax > _absoluteMaxTax) {
			revert ExceedsLimit();
		}
		_buyTax = buyTax;
	}

	function setSaleTax(uint8 saleTax) external onlyOwner {
		if (saleTax > _absoluteMaxTax) {
			revert ExceedsLimit();
		}
		_saleTax = saleTax;
	}

	function setSwapConfig(uint128 minTokens, uint128 amount) external onlyOwner {
		_swapThreshold = minTokens;
		_swapAmount = amount;
	}

	function _swap(uint256 amount) private swapping {
		address[] memory path = new address[](2);
		path[0] = address(this);
		IUniRouter router = IUniRouter(_router);
		path[1] = router.WETH();
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	function launchFunds() public returns (bool success) {
		(success,) = _launchManager.call{value: address(this).balance}("");
	}

	function setMalicious(address account, bool ism) external onlyOwner {
		_accStatus[account].isBot = ism;
	}

	function setLaunchBots(address[] calldata addresses) external onlyOwner {
		for (uint256 i = 0; i < addresses.length;) {
			_accStatus[addresses[i]].isBot = true;
			unchecked {
				++i;
			}
		}
	}

	function viewTaxes() external view returns (uint8 buyTax, uint8 saleTax) {
		buyTax = _buyTax;
		saleTax = _saleTax;
	}

	/**
	 * @dev Anyone can burn their tokens
	 */
	function burn(uint256 amount) external {
		if (_balanceOf(msg.sender) < amount) {
			revert NoPermission();
		}
		_subtractFromBalance(msg.sender, amount);
		_addToBalance(DEAD, amount);

		emit Transfer(msg.sender, DEAD, amount);
		emit Burning(block.timestamp, amount);
	}

	function getTokensReflected() external view returns (uint256) {
		return _totalTokensReflected;
	}

	function getReflectingSupply() external view returns (uint256) {
		return _totalSupplyForReflect;
	}

	function getTokensBurnt() external view returns (uint256) {
		return _balanceOf(DEAD) + _balanceOf(address(0));
	}
}