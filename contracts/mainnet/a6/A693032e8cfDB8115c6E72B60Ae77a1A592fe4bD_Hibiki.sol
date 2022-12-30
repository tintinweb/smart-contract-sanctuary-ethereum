/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

/**
 * Tooling and development for EVM blockchains.
 *
 * https://hibiki.finance
 * https://t.me/hibikifinance 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract Auth {

    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Detailed is IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
}

contract Hibiki is IERC20Detailed, Auth {

	string constant private _name = "Hibiki.finance";
    string constant private _symbol = "HIBIKI";
    uint256 constant private _totalSupply = 10_000_000 ether;

	mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isFeeExempt;
	mapping (address => bool) private _isTaxable;

	uint256 public ammTradeFee = 2_00;
	uint256 constant public maxFee = 5_00;
    uint256 constant public feeDenominator = 100_00;
	address public feeReceiver;
	address constant private DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant private ZERO = 0x0000000000000000000000000000000000000000;

	event AMMFeeUpdate(uint256 fee, address receiver);
	error FeeTooHigh(uint256 attemptedFee, uint256 maxFee);
	error InsufficientAllowance(uint256 attempted, uint256 available);
	error InsufficientBalance(uint256 attempted, uint256 available);
	error ApproveFromZero();
	error ApproveToZero();
	error TransferFromZero();
	error TransferToZero();

	constructor() Auth(msg.sender) {
		_balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return 18; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }

	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		address owner = msg.sender;
		_approve(owner, spender, allowance(owner, spender) + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		address owner = msg.sender;
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance < subtractedValue) {
			revert InsufficientAllowance(subtractedValue, currentAllowance);
		}
		unchecked {
			_approve(owner, spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		if (owner == ZERO) {
			revert ApproveFromZero();
		}
		if (spender == ZERO) {
			revert ApproveToZero();
		}
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

	function _spendAllowance(address owner, address spender, uint256 amount) internal {
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			if (currentAllowance < amount) {
				revert InsufficientAllowance(amount, currentAllowance);
			}
			unchecked {
				_approve(owner, spender, currentAllowance - amount);
			}
		}
	}

    function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(msg.sender, recipient, amount);
        return true;
    }

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) public virtual override returns (bool) {
		_spendAllowance(from, msg.sender, amount);
		_transfer(from, to, amount);
		return true;
	}

	function _transfer(address from, address to, uint256 amount) internal virtual {
		if (from == ZERO) {
			revert TransferFromZero();
		}
		if (to == ZERO) {
			revert TransferToZero();
		}

		uint256 fromBalance = _balances[from];
		if (fromBalance < amount) {
			revert InsufficientBalance(amount, fromBalance);
		}

		uint256 receivedAmount = amount;
		if (_isTransferTaxable(from, to)) {
			uint256 fee = _calcFee(amount);
			if (fee > 0) {
				address receivesFee = feeReceiver;
				unchecked {
					receivedAmount -= fee;
					_balances[receivesFee] += fee;
				}
				
				emit Transfer(from, receivesFee, fee);
			}
		}

		unchecked {
			_balances[from] = fromBalance - amount;
			_balances[to] += receivedAmount;
		}

		emit Transfer(from, to, receivedAmount);
	}

	function _calcFee(uint256 amount) internal view returns (uint256) {
		uint256 tradeFee = ammTradeFee;
		if (tradeFee == 0) {
			return 0;
		}

		return amount * tradeFee / feeDenominator;
	}

	function _isTransferTaxable(address sender, address recipient) internal view returns (bool) {
		return (_isTaxable[sender] || _isTaxable[recipient])
			&& !_isFeeExempt[sender]
			&& !_isFeeExempt[recipient];
	}

    function setIsFeeExempt(address wallet, bool exempt) external authorized {
        _isFeeExempt[wallet] = exempt;
    }

	function setIsTaxable(address wallet, bool taxable) external authorized {
        _isTaxable[wallet] = taxable;
    }

    function setAMMTradingFee(uint256 newFee, address newReceiver) external authorized {
		uint256 max = maxFee;
		if (newFee > max) {
			revert FeeTooHigh(newFee, max);
		}
		ammTradeFee = newFee;
		feeReceiver = newReceiver;

        emit AMMFeeUpdate(newFee, newReceiver);
    }

	function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }
}