/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 amount) external returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

abstract contract ERC20 is IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances; //owner => balance;
    mapping(address => mapping(address => uint256)) private _allowances; // owner => (spender => amount)

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return _balances[owner];
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool success)
    {
        _transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool success)
    {
        _approve(msg.sender, spender, amount);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return _allowances[owner][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool success) {
        if (from != msg.sender) {
            uint256 allowanceAmount = _allowances[from][msg.sender];
            require(
                amount <= allowanceAmount,
                "transfer amount exceeds allowance"
            );
            _approve(from, msg.sender, allowanceAmount - amount);
            _transfer(from, to, amount);
        }

        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "transfer from zero address");
        require(to != address(0), "transfer ro zero address");
        require(amount <= _balances[from], "transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] -= amount;

        emit Transfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "approve from zero address");
        require(spender != address(0), "approve spender zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "mint to zero address");

        _balances[to] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), msg.sender, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "burn from zero address");
        require(amount <= _balances[from], "burn amount exceeds balance");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }
}

contract TheGraph is ERC20 {
    constructor() ERC20("TheGraph", "TGH") {
        _mint(msg.sender, 10000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}