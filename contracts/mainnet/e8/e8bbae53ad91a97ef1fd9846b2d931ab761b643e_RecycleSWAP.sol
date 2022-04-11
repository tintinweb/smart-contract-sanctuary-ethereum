/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

/**
 >> RecycleSWAP Project <<
 APRIL 8, 2022

 https://recycleswap.net
 Initial Supply: 369,888,369,888 RCX
 NAME: RecycleSwap
 Symbol: RCX

RecycleSWAP (RCX) Project is a recycling solution.
The mechanism will authorize the dead coin and token
holders, to transfer their coins to the RecycleSWAP and 
get its tradable coin instead. This will be at restored 
value to individual holders who can sell, trade, stake, 
liquidate tokens into pools, or circulate their RecycleSWAP 
tokens in to the market, and the recycling of project assets 
back into the community.
 
Regarding to the conceptual description of recycling, and 
its multifunction methodologies, it is clear that the main 
reason of RecycleSWAP Project is economics and the potential 
behind its recycleing strategy, considering the technical 
requirements it's supposed to fullfil. The RecycleSWAP is 
going to perform an economic task that no other asset could 
carry out since the birth of Bitcoin.
RecycleSWAP tokens have potential to restore a portion of 
the value from other currencies that were reduced because 
of lack of the demand, or lost by a rug pull from its 
developers or large holders. 

Proposed Solution
-----------------
1. Revaluation of dead coin and tokens.
2. Set up a system to restore and transfer this trapped value 
in a user-friendly platform.
3. RecycleSWAP Token is a convertible token to transferable 
real coin.
4. RecycleSWAP Token Holders can trade their valueless tokens 
and coins into Bitcoin, Ethereum, Solano, and other leading 
cryptocurrencies will be listed @ RCX Official Website.
5. Unifying of failed and dead coin holders, will permit the 
RecycleSWAP Project to clean up the market, and effectively 
eliminate the remaining coins to retain their value.
6. RecycleSWAP is the fast and effective way to reform and 
rehabilitate the value of the market.
7. RecycleSWAP holders will have an opportunity to reinvest 
their regenerated tokens to tradable cryptocurrency projects.
8. RecycleSWAP aims to implement and integrate projects, with 
the power of its holders.


Tokenomics
----------
 10% First stage ICO
 30% Add Liquidity to the market
 25% R&D
 30% Reserve in contract (Control value of coin)
 5% Reserve for the future partners and exchangers


At this point, it should be clear to any holder that listing 
RecycleSWAP on exchanges is a critical element in the success 
of this phase of the RecycleSWAP project. Without listing, 
RecycleSWAP cannot offer a proper gateway to our communities
in order to release value of their dead tokens and coins, into 
the market. 
Although there are no guarantees that any cryptocurrency or 
token will ever get listed on any exchange, the RecycleSWAP 
team has been holding talks with various exchanges to list 
RecycleSWAP (RCX) token once it enters the market.


*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface RCX {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address from, address to,  uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface RCXMetadata is RCX {
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

contract RecycleSWAP is Context, RCX, RCXMetadata {
    address public admin;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, 369888369888 * 10 ** 18);
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
        require(currentAllowance >= subtractedValue, "RCX: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer( address from, address to, uint256 amount ) internal virtual {
        require(from != address(0), "RCX: transfer from the zero address");
        require(to != address(0), "RCX: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "RCX: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "RCX: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "RCX: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "RCX: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);

    }

    function _approve( address owner, address spender, uint256 amount ) internal virtual {
        require(owner != address(0), "RCX: approve from the zero address");
        require(spender != address(0), "RCX: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance( address owner, address spender, uint256 amount ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "RCX: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer( address from, address to, uint256 amount ) internal virtual {}
    function _afterTokenTransfer( address from, address to, uint256 amount ) internal virtual {}
}