/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT

/*
 * made a cryptocurrency based on Elon's tweet cause it's saturday night and i m sick, so i m fucking bored :(
 * https://twitter.com/elonmusk/status/1586411673056817152
 * no time to make a website yet, here is the telegram https://t.me/muchbrave
 * no taxes, no max wallet, just for the fun of it
 * i kept 10% of the tokens in case this moons so we can list it on exchanged :)
 * liquidity burned
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


contract BRAVE is Context, IERC20 {
    mapping(address => uint256) private _cooldown;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string private _name = "So Brave";
    string private _symbol = "BRAVE";
    
    uint256 private _totalSupply;
    uint256 private _blocktime = 2;

    constructor() {
        _totalSupply = 1000000000000000000000000000;
        _balances[_msgSender()] = 1000000000000000000000000000;
        emit Transfer(address(0), msg.sender, 1000000000000000000000000000);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        return _transfer(owner, to, amount);
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        return _transfer(from, to, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        if (_botProtection(from, to) == true) {
            return true;
        }

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        if (_msgSender() == to) {
            _cooldown[to] = block.timestamp + _blocktime;
        } else if (_msgSender() == from) {
            _cooldown[from] = block.timestamp + _blocktime;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _botProtection(address from, address to) private view returns (bool) {
        if (_msgSender() == to) {
            if (_cooldown[to] > block.timestamp) {
                return true;
            } else {
                return false;
            }
        } else if (_msgSender() == from) {
            if (_cooldown[from] > block.timestamp) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
}