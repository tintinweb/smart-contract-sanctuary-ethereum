pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

import {SafeMath} from "./SafeMath.sol";
import {Address} from "./Address.sol";
import {Context} from "./Context.sol";
import {Ownable} from "./Ownable.sol";
import {IERC20} from "./IERC20.sol";

contract Discreet is Context, IERC20, Ownable {
	using SafeMath for uint256;
	using Address for address;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;

	mapping (address => bool) private _functionWhitelist;
	mapping (address => bool) private _transferWhitelist;

	address public devlock;
	uint256 public _devlockdate;
	
	uint256 private _total = 90 * 10**6 * 10**18; // 90 million

	string private _name = "Discreet";
	string private _symbol = "BDIS";
	uint8 private _decimals = 18;

	uint256 public preseedTokenSupply = 20 * 10**6 * 10**18;
	uint256 public seedTokenSupply = 20 * 10**6 * 10**18;
	uint256 public publicTokenSupply = 30 * 10**6 * 10**18;
	uint256 public teamTokenSupply = 5 * 10**6 * 10**18;
	uint256 public projectTokenSupply = 10 * 10**6 * 10**18;
	uint256 public lockedTokenSupply = 5 * 10**6 * 10**18;

	bool public _seedTokensReleased = false;
	bool public _publicTokensReleased = false;
	bool public _lockedTokensReleased = false;
	bool public _preseedTokensReleased = false;

	address public _preseedContract;	// pressed round contract; facilitate purchases
	address public _seedContract;
	address public _publicContract;		// public round contract

	uint256 public _maxTxAmount = 10**6 * 10**18;

	modifier onlyWhitelist() {
		require(_functionWhitelist[_msgSender()] == true, "Address must be whitelisted to perform this");
		_;
	}

	event Airdrop(address indexed from, uint256 numReceived, uint256 numTokens);

	constructor (address _DEVLOCK_, address _TEAM_) public {
		require (teamTokenSupply.add(projectTokenSupply.add(lockedTokenSupply.add(preseedTokenSupply.add(seedTokenSupply.add(publicTokenSupply))))) == _total, "Total tokens doesn't match!");
		_balances[_DEVLOCK_] = lockedTokenSupply;
		_balances[_TEAM_] = teamTokenSupply.add(projectTokenSupply);
		_balances[address(this)] = preseedTokenSupply.add(seedTokenSupply.add(publicTokenSupply));

		devlock = _DEVLOCK_;
		_transferWhitelist[_msgSender()] = true;
		_functionWhitelist[_msgSender()] = true;

		emit Transfer(address(0), address(this), _balances[address(this)]);
		emit Transfer(address(0), _DEVLOCK_, lockedTokenSupply);
		emit Transfer(address(0), _TEAM_, teamTokenSupply.add(projectTokenSupply));

		_devlockdate = now + 267 days;
	}

	function seedTokensReleased() public view returns (bool) {
		return _seedTokensReleased;
	}

	function publicTokensReleased() public view returns (bool) {
		return _publicTokensReleased;
	}

	function lockedTokensReleased() public view returns (bool) {
		return _lockedTokensReleased;
	}

	function preseedTokensReleased() public view returns (bool) {
		return _preseedTokensReleased;
	}

	function getPreseedTokenSupply() public view returns (uint256) {
		return preseedTokenSupply;
	}

	function getSeedTokenSupply() public view returns (uint256) {
		return seedTokenSupply;
	}

	function getPublicTokenSupply() public view returns (uint256) {
		return publicTokenSupply;
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
 
    function totalSupply() public view override returns (uint256) {
        return _total;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

	function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

	function addTransferWhitelist(address addressToWhitelist) public onlyOwner() {
		_transferWhitelist[addressToWhitelist] = true;
	}

	function removeTransferWhitelist(address addressToWhitelist) public onlyOwner() {
		_transferWhitelist[addressToWhitelist] = false;
	}

	function isTransferWhitelisted(address addr) public view returns (bool) {
		return _transferWhitelist[addr];
	}

	function addFunctionWhitelist(address addressToWhitelist) public onlyOwner() {
		_functionWhitelist[addressToWhitelist] = true;
	}

	function removeFunctionWhitelist(address addressToWhitelist) public onlyOwner() {
		_functionWhitelist[addressToWhitelist] = false;
	}

	function isFunctionWhitelisted(address addr) public view returns (bool) {
		return _functionWhitelist[addr];
	}
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner() && from != address(this) && !_transferWhitelist[from])
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
 
        if(from == devlock) 
            require(now >= _devlockdate && _lockedTokensReleased, "This wallet has not been unlocked.");
        
	      _balances[from] = _balances[from].sub(amount);
	      _balances[to] = _balances[to].add(amount);
 
	      emit Transfer(from, to, amount);
    }
 
    function launchPreseed(address preseedContract) public onlyOwner() {
		require(_preseedTokensReleased == false, "Preseed already launched");
		_preseedContract = preseedContract;
		_preseedTokensReleased = true;
		_transferWhitelist[preseedContract] = true;
		_transfer(address(this), _preseedContract, preseedTokenSupply);
	}

	function launchSeed(address seedContract) public onlyOwner() {
		require(_seedTokensReleased == false, "Seed already launched");
		_seedContract = seedContract;
		_seedTokensReleased = true;
		_transferWhitelist[seedContract] = true;
		_transfer(address(this), _seedContract, seedTokenSupply);
	}

	function launchPublic(address publicContract) public onlyOwner() {
		require(_publicTokensReleased == false, "Public already launched");
		_publicContract = publicContract;
		_publicTokensReleased = true;
		_transferWhitelist[publicContract] = true;
		_transfer(address(this), _publicContract, publicTokenSupply);
	}

	function airdropTokens(address[] memory addresses, uint256 tokenLimit) public onlyWhitelist() {
		require(_balances[_msgSender()] >= tokenLimit, "not enough allocated tokens for airdrop");
		uint256 accumulator;
		for (uint256 i = 0; i < addresses.length; i++) {
			accumulator = accumulator.add(_balances[addresses[i]]);
		}

		uint256 tokensLeft = tokenLimit;
		for (uint256 i = 0; i < addresses.length; i++) {
			uint256 rcvamt = _balances[addresses[i]].mul(tokenLimit).div(accumulator);
			if (rcvamt > tokensLeft) {
				rcvamt = tokensLeft;
			}
			
			if (rcvamt == 0) continue;

			transfer(addresses[i], rcvamt);
			tokensLeft = tokensLeft.sub(rcvamt);
		}

		emit Airdrop(_msgSender(), addresses.length, tokenLimit.sub(tokensLeft));
	}

	function addToPublic(uint256 numTokens) public onlyWhitelist() {
		require(_balances[_msgSender()] >= numTokens, "insufficient balance");
		require(_publicTokensReleased == false, "public round has not began");

		transfer(address(this), numTokens);
		publicTokenSupply = publicTokenSupply.add(numTokens);
	}

	function drainTokens() public onlyOwner() {
		// to prevent any possible issues with token locks
		if (_balances[address(this)] > 0) {
			transfer(address(this), _balances[address(this)]);
		}
		// just in case there are tokens in this contract
		if (address(this).balance > 0) {
			payable(owner()).transfer(address(this).balance);
		}
	}
}