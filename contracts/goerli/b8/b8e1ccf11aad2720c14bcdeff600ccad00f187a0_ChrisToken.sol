/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: UNLICENSED;

pragma solidity ^0.8.7;


contract ChrisToken{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) isBlacklisted;

    address private Owner;

    constructor() {
        Owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    modifier onlyOwner{
        require (msg.sender == Owner, "Error: You are not the owner !");
        _;
    }

    uint256 private _totalSupply = 1400 * 10**_decimals;
    uint256 private _maxSupply = 40000 *10**_decimals;
    uint8 private constant _decimals = 10;
    string private constant _name = "ChrisToken";
    string private constant _symbol = "CTK";



    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        require(!isBlacklisted[msg.sender], "Error: You are blacklisted by the owner !");
        require(!isBlacklisted[to], "Error: Address recipient blacklisted !");
        address sender = msg.sender;
        _transfer(sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        require(!isBlacklisted[from], "Error: You are blacklisted by the owner !");
        require(!isBlacklisted[to], "Error: Adress blacklisted");
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "Error: decreased allowance below zero");
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
        require(from != address(0), "Error: transfer from the zero address");
        require(to != address(0), "Error: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Error: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;

            _balances[to] += amount;
        }

        _afterTokenTransfer(from, to, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner virtual {
        require(account != address(0), "Error: mint to the zero address");
        require((_totalSupply + amount) <= _maxSupply, "Error: Exceed max supply !");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }

        _afterTokenTransfer(address(0), account, amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Error: approve from the zero address");
        require(spender != address(0), "Error: approve to the zero address");

        _allowances[owner][spender] = amount;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Error: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function blackList(address _user) public onlyOwner {
        require(!isBlacklisted[_user], "Error: user already blacklisted");
        isBlacklisted[_user] = true;
    }
    
    function removeBlacklist(address _user) public onlyOwner {
        require(isBlacklisted[_user], "Error: user already whitelisted");
        isBlacklisted[_user] = false;
    }

    function isBlacklist(address _user) external view returns (bool) {
        return isBlacklisted[_user];
    }
}