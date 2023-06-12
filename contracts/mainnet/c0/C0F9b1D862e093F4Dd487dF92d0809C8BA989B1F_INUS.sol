/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

/**
 A Bunch of Inus Combined, forming Inus Community
 https://www.inuscommunity.com/
 https://t.me/InusCommunity
 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract Ownership {

	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	error NotOwner();

	modifier onlyOwner {
		if (msg.sender != owner) {
			revert NotOwner();
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

interface IRouter {
	function WETH() external pure returns (address);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract INUS is Ownership {

	uint256 constant internal _totalSupply = 420_420_420 gwei;
	string internal _name = "INUS COMMUNITY";
	string internal _symbol = "INUS";
	uint8 constant internal _decimals = 9;

	uint256 private immutable _maxTx;
	uint256 private immutable _maxWallet;

	bool private _inSwap;
	bool public launched;
	bool public limited = true;
	uint8 private _buyTax = 30;
    uint8 private _saleTax = 30;
	address private _pair;
	address payable private immutable _deployer;
	address private _router;
	uint128 private _swapThreshold;
	uint128 private _swapAmount;

	mapping (address => bool) private _isBot;
	mapping (address => uint256) internal _balances;
	mapping (address => mapping (address => uint256)) internal _allowances;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	error ExceedsAllowance();
	error ExceedsBalance();
	error ExceedsLimit();
	error NotTradeable();

	modifier swapping {
		_inSwap = true;
		_;
		_inSwap = false;
	}

	constructor(address router) Ownership(msg.sender) {
		_router = router;
		_deployer = payable(msg.sender);
		_maxTx = _totalSupply / 50;
		_maxWallet = _totalSupply / 50;
		_swapThreshold = uint128(_totalSupply);
		_approve(address(this), router, type(uint256).max);
		_approve(msg.sender, router, type(uint256).max);
		_balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	function name() external view returns (string memory) {
		return _name;
	}

	function symbol() external view returns (string memory) {
		return _symbol;
	}

	function decimals() external pure returns (uint8) {
		return _decimals;
	}

	function totalSupply() external pure returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
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

	function _approve(address owner_, address spender, uint256 amount) internal {
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

	function _transfer(address sender, address recipient, uint256 amount) internal {
		uint256 senderBalance = _balances[sender];
		if (senderBalance < amount) {
			revert ExceedsBalance();
		}
		uint256 amountReceived = _beforeTokenTransfer(sender, recipient, amount);
		unchecked {
			_balances[sender] = senderBalance - amount;
			_balances[recipient] += amountReceived;
		}

		emit Transfer(sender, recipient, amountReceived);
	}

	receive() external payable {}

	function FuckingSendIt(address tradingPair) external onlyOwner {
		_pair = tradingPair;
		launched = true;
	}

	function setTradingPair(address tradingPair) external onlyOwner {
		_pair = tradingPair;
	}

	function setRouter(address r) external onlyOwner {
		_router = r;
	}

	function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal returns (uint256) {
		address dep = _deployer;
		if (tx.origin == dep || sender == dep || recipient == dep || sender == address(this)) {
			return amount;
		}

		if (!launched || _isBot[sender] || _isBot[recipient]) {
			revert NotTradeable();
		}

		address tradingPair = _pair;
		bool isBuy = sender == tradingPair;
		bool isSale = recipient == tradingPair;
		uint256 amountToRecieve = amount;

		if (isSale) {
			uint256 contractBalance = balanceOf(address(this));
			if (contractBalance > 0) {
				if (!_inSwap && contractBalance >= _swapThreshold) {
					_sellAndFund(contractBalance);
				}
			}

			uint8 saleTax = _saleTax;
			if (saleTax > 0) {
				uint256 fee = amount * _saleTax / 100;
				unchecked {
					// fee cannot be higher than amount
					amountToRecieve = amount - fee;
					_balances[address(this)] += fee;
				}
				emit Transfer(sender, address(this), fee);
			}
		}

		if (isBuy) {
			uint256 buyTax = _buyTax;
			if (buyTax > 0) {
				uint256 fee = amount * _buyTax / 100;
				unchecked {
					amountToRecieve = amount - fee;
					_balances[address(this)] += fee;
				}
				emit Transfer(sender, address(this), fee);
			}
		}

		if (recipient != address(this)) {
			if (limited) {
				if (
					amountToRecieve > _maxTx
					|| (!isSale && balanceOf(recipient) + amountToRecieve > _maxWallet)
				) {
					revert ExceedsLimit();
				}
			}
		}

		return amountToRecieve;
	}

	/**
	 * @dev Removes wallet and TX limits. Cannot be undone.
	 */
	function setUnlimited() external onlyOwner {
		limited = false;
	}

	function _renounceOwnership() internal override {
		_buyTax = 0;
		_saleTax = 0;
		limited = false;
		super._renounceOwnership();
	}

	function setBuyTax(uint8 buyTax) external onlyOwner {
		if (buyTax > 99) {
			revert ExceedsLimit();
		}
		_buyTax = buyTax;
	}

	function setSaleTax(uint8 saleTax) external onlyOwner {
		if (saleTax > 99) {
			revert ExceedsLimit();
		}
		_saleTax = saleTax;
	}

	function setSwapSettings(uint128 thres, uint128 amount) external onlyOwner {
		_swapThreshold = thres;
		_swapAmount = amount;
	}

	function _swap(uint256 amount) private swapping {
		address[] memory path = new address[](2);
		path[0] = address(this);
		IRouter router = IRouter(_router);
		path[1] = router.WETH();
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	function _sellAndFund(uint256 contractBalance) private {
		uint256 maxSwap = _swapAmount;
		uint256 toSwap = contractBalance > maxSwap ? maxSwap : contractBalance;
		if (toSwap > 0) {
			_swap(toSwap);
		}
		launchFunds();
	}

	function launchFunds() public returns (bool success) {
		(success,) = _deployer.call{value: address(this).balance}("");
	}

	function catchMaliciousActors(address[] calldata malicious) external onlyOwner {
		for (uint256 i = 0; i < malicious.length; i++) {
			_isBot[malicious[i]] = true;
		}
	}

	function setMark(address account, bool m) external onlyOwner {
		_isBot[account] = m;
	}

	function getTaxes() external view returns (uint8 buyTax, uint8 saleTax) {
		buyTax = _buyTax;
		saleTax = _saleTax;
	}
}