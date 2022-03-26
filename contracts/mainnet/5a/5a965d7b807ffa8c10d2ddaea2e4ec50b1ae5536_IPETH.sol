/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function creator() external view returns (address);
    function decimals() external view returns (uint256);
}

contract ERC20 is IERC20, IERC20Metadata {
    string  private _name;
    string  private _symbol;
    address private _creator;
    uint256 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_, uint256 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _creator = msg.sender;
    }

    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function creator() public view virtual override returns (address) { return _creator; }
    function decimals() public view virtual override returns (uint256) { return _decimals; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        _updateAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        uint256 fromBalance = _balances[from];
        require(from != address(0), "Error: Transfer Initiated from address(0)!");
        require(to != address(0), "Error: Transfer Initiated towards address(0)!");
        require(fromBalance >= amount, "Error: Transfer Amount Exceeds Balance!");
        unchecked { _balances[from] = fromBalance - amount; }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Error: Mint Order is to address(0)!");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Error: Approved from address(0)!");
        require(spender != address(0), "Error: Approved to address(0)!");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _updateAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Error: Insufficient Allowance!");
            unchecked { _approve(owner, spender, currentAllowance - amount); }
        }
    }
}

contract IPETH is ERC20 {
    address private admin;
    event Received(address sender, uint256 value);
    event Withdrew(address withdrawer, uint256 amount, string tokenType);

    constructor() ERC20("Inter-Planetary Ethereum", "IPETH", 18) {
        admin = msg.sender;
        _mint(msg.sender, 80000000 * 10 ** 18);
    }

    function withdraw(uint256 _amount) external payable {
        uint256 amount = address(this).balance;
        require(msg.sender == admin, "Error: Action Restricted!");
        require(amount >= _amount, "Error: Balance is Lower than Requested Amount!");
        address payable to = payable(msg.sender);
        to.transfer(_amount);
        emit Withdrew(msg.sender, _amount, "ETH");
    }

    function withdrawTokens(IERC20 token, uint256 _amount) external {
        uint256 amount = token.balanceOf(address(this));
        require(msg.sender == admin, "Error: Action Restricted!");
        require(amount >= _amount, "Error: Balance is Lower than Requested Amount!");
        token.transfer(msg.sender, _amount);
        emit Withdrew(msg.sender, _amount, "ERC20");
    }

    receive() external payable { emit Received(msg.sender, msg.value); }
    fallback() external payable { emit Received(msg.sender, msg.value); }
}