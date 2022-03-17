/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

/**
        >￠x | CX.CASH

>￠x:\NAME>  CXCASH
>￠x:\SYMBOL> CXS
>￠x:\Initial Supply> ￠1,000,000,000
>￠x:\Decimals> 18
>￠x:\Public Liquidity> 18%
>￠x:\Development> 15%
>￠x:\Community Rewards> 2%
>￠x:\Decentralized Reserve> 65%
>￠x:\Websites> cx.cash - cxcash.org
>￠x:\GITHUB> cxcash
>￠x:\Community> https://t.me/cxcash

$ This story is completely TRUE.
$ Inflation is real and happening. It needs to be taken as a serious problem for the future of market.
$ Let's bring back trust to the market, together.
$ CXCASH = Blockchain Solutions + AI + Innovative Evolution
$ CXCASH | Decentralized Micropayment System (DMPS); one of the solutions which will bring back value to the market by offering, low gas/network fee, simple and user friendly APIs and GUIs, cost reduction in mining equipment, capability of processing micro transactions, Quantum Computing Solutions, and more.
$ Although future is not set on the stone, CXCash Project is committed to bringing great new 
opportunities to the market.
$ A project that creates future, today.


>￠x:\Targets-Burn Layout>

1st Target. Centralized Free API Service that process decetralized micro payments.
Implementation @ 1,200 ETH worth of CXCASH.
1st Burn. 1% of Remaining CXCASH.

2nd Target. Decentralized API Service that process DMPS.
Implementation @ 15,000 ETH worth of CXCASH.
2nd Burn. 9% of Remaining CXCASH.

3rd Target. Exchange CXS Tokens to the minable coin.
Implementation @ 69,000 ETH worth of CXCASH.
3rd Burn. 90% of Remaining CXCASH.

>￠x:\Author Alias>: TAZASU
*/


// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface CX20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address from, address to,  uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface CX20Metadata is CX20 {
 
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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract CXCASH is Context, CX20, CX20Metadata {

    address public admin;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, 1000000000 * 10 ** 18);
        admin = msg.sender;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
 
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

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

    function transferFrom( address from, address to, uint256 amount ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "CX20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer( address from, address to, uint256 amount ) internal virtual {
        require(from != address(0), "CX20: transfer from the zero address");
        require(to != address(0), "CX20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "CX20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "CX20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "CX20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "CX20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);

    }

    function _approve( address owner, address spender, uint256 amount ) internal virtual {
        require(owner != address(0), "CX20: approve from the zero address");
        require(spender != address(0), "CX20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

 
    function _spendAllowance( address owner, address spender, uint256 amount ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "CX20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer( address from, address to, uint256 amount ) internal virtual {}

    function _afterTokenTransfer( address from, address to, uint256 amount ) internal virtual {}
}