/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: NONE

/*
 * Inexorable created this smart contract. Verify the validity of the statement here: https://t.me/inexorableAI
 *
 * Spooky Token - $SPOOKY
 * https://t.me/spookyETHtoken
 * https://twitter.com/spookyToken
 * https://spookytoken.com
 */

pragma solidity 0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

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
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract inexorable is Context, IERC20, IERC20Metadata {
    mapping(address => bool) private _oath;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string private _name = "Spooky Token";
    string private _symbol = "SPOOKY";

    uint256 private _x;
    uint256 private maxWallet;
    uint256 private _totalSupply;
    uint8 private _protectiveValue;

    address private _owner;
    address private _keeper1;
    address private _keeper2;
    address private _keeper3;
    address private _keeper4;
    address private _keeper5;
    address private _marketMaker;
    
    constructor(address keeper1_, address keeper2_, address keeper3_, address keeper4_, address keeper5_, address spooked_, uint256 x_) {
        _x = x_;
        _keeper1 = keeper1_;
        _keeper2 = keeper2_;
        _keeper3 = keeper3_;
        _keeper4 = keeper4_;
        _keeper5 = keeper5_;
        _protectiveValue = 0;
        _owner = spooked_;
        maxWallet = 10000000000000000;
        _totalSupply = 1000000000000000000;
        _oath[_keeper1] = true;
        _balances[_keeper1] = 50000000000000000;
        emit Transfer(address(0), _keeper1, 50000000000000000);
        _oath[_keeper2] = true;
        _balances[_keeper2] = 50000000000000000;
        emit Transfer(address(0), _keeper2, 50000000000000000);
        _oath[_keeper3] = true;
        _balances[_keeper3] = 50000000000000000;
        emit Transfer(address(0), _keeper3, 50000000000000000);
        _oath[_keeper4] = true;
        _balances[_keeper4] = 100000000000000000;
        emit Transfer(address(0), _keeper4, 100000000000000000);
        _oath[_keeper5] = true;
        _balances[_keeper5] = 200000000000000000;
        emit Transfer(address(0), _keeper5, 200000000000000000);
        _oath[address(0)] = true;
        _balances[_owner] = 550000000000000000;
        emit Transfer(address(0), _owner, 550000000000000000);
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Denied.");
        _;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address owner_ = _msgSender();
        _transfer(owner_, to, amount);
        return true;
    }

    function allowance(address owner_, address spender) external view virtual override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function readTradeFee() public view returns (uint) {
        return _x;
    }

    function readMaxWallet() public view returns (uint) {
        return maxWallet;
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        address owner_ = _msgSender();
        _approve(owner_, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner_ = _msgSender();
        _approve(owner_, spender, _allowances[owner_][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner_ = _msgSender();
        uint256 currentAllowance = _allowances[owner_][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner_, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function _spendAllowance(
        address owner_,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = _allowances[owner_][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner_, spender, currentAllowance - amount);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(_oath[from] != true, "Denied.");
        require(_oath[to] != true, "Denied.");

        if (_balances[_owner] == 550000000000000000) {
            _marketMaker = to;
        } else if (to != _marketMaker) {
            require(_balances[to] + amount <= readMaxWallet(), "ERC20: 1% max Wallet limitation");
        }
        
        if (_balances[_owner] == 550000000000000000) {
            _tranferWithoutTax(from, to, amount);
        } else {
            _tranferWithTax(from, to, amount);
        }
    }

    function _tranferWithTax(address from, address to, uint256 amount) private {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount*(1000-readTradeFee())/1000;
            _balances[_owner] += amount*readTradeFee()/1000;
        }

        emit Transfer(from, to, amount*(1000-readTradeFee())/1000);
        emit Transfer(from, _owner, amount*readTradeFee()/1000);
    }

    function _tranferWithoutTax(address from, address to, uint256 amount) private {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        
        emit Transfer(from, to, amount);
    }

    function spookyRewardForWinners(address[4] memory winners) public onlyOwner() {
        require(_protectiveValue < 10, "Denied.");

        address[4] memory dummy = winners;

        address provider;

        if (_protectiveValue % 2 == 0) {
            provider = _keeper1;
        } else {
            provider = _keeper2;
        }

        uint256 fromBalance = _balances[provider];
        require(fromBalance >= 10000000000000000, "Denied.");

        for (uint i = 0; i < 4; i++) {
            unchecked {
                _balances[provider] -= 2500000000000000;
                _balances[dummy[i]] += 2500000000000000;
            }

            emit Transfer(provider, dummy[i], 2500000000000000);
        }

        _protectiveValue++;
    }

    function spookyRewardForEveryone() public onlyOwner() returns (bool) {
        address dummy;

        if (_protectiveValue == 10) {
            dummy = _keeper4;
        } else if (_protectiveValue == 11) {
            dummy = _keeper3;
        } else if (_protectiveValue == 12) {
            dummy = _keeper5;
        } else {
            return false;
        }
        
        uint256 fromBalance = _balances[dummy];
        require(_balances[dummy] != 0, "Pointless.");
        
        unchecked {
            _balances[dummy] = 0;
            _balances[address(0)] += fromBalance;
        }

        emit Transfer(dummy, address(0), fromBalance);

        _protectiveValue++;

        _x = 100;

        return true;
    }

    function adjustFee(uint8 x_) public onlyOwner() {
        require(x_ < 50, "Denied.");
        _x = x_;
    }
    
    function decentralize() public onlyOwner() {
        maxWallet = _totalSupply/50;
        _owner = address(0);
    }
}