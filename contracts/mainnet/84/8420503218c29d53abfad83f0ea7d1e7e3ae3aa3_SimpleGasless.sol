// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC2771Context.sol";
import "./Ownable.sol";

contract SimpleGasless is ERC2771Context {
    address private _owner;
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address trustedForwarder, address owner) ERC2771Context(trustedForwarder) {
        _owner = owner;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function getOwner() public view virtual returns (address) {
        return _owner;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        require(to != address(0), "SimpleGasless: mint to the zero address");
        
        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            // solidity 0.8 defaults to throwing an error on over/underflows.
            _balances[to] += amount;
        }
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public virtual {
        address account = _msgSender();

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "SimpleGasless: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address from = _msgSender();
        require(to != address(0), "SimpleGassless: transfer to the zero address");
        
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "SimpleGassless: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);

        return true;
    }

    function _checkOwner() internal view virtual {
        require(getOwner() == _msgSender(), "SimpleGasless: caller is not the owner");
    }
}