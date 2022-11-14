// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC20 is IERC20 {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    string internal name_;
    string internal symbol_;
    uint8 internal decimals_;

    function name() external view override returns (string memory) {
        return name_;
    }

    function symbol() external view override returns (string memory) {
        return symbol_;
    }

    function decimals() external view override returns (uint8) {
        return decimals_;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 sender_allowance = _allowances[sender][msg.sender];
        require(sender_allowance >= amount, "ERC20: transfer exceeds allowance");
        _approve(sender, msg.sender, sender_allowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 spender_allowance = _allowances[msg.sender][spender];
        require(spender_allowance + addedValue >= spender_allowance, "ERC20: Overflow");
        _approve(msg.sender, spender, spender_allowance + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 sender_allowance = _allowances[msg.sender][spender];
        require(sender_allowance >= subtractedValue, "ERC20: transfer exceeds allowance");
        _approve(msg.sender, spender, sender_allowance - subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 sender_balance = _balances[sender];
        uint256 recipient_balance = _balances[recipient];
        require(sender_balance >= amount, "ERC20: transfer amount exceeds balance");
        require(recipient_balance + amount >= recipient_balance, "ERC20: Overflow");
        _balances[sender] = sender_balance - amount;
        _balances[recipient] = recipient_balance + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        uint256 _total = _totalSupply;
        require(_total + amount >= _total, "ERC20: Overflow");
        _totalSupply = _total + amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 current_balance = _balances[account];
        require(current_balance >= value, "ERC20: burn amount exceeds balance");
        _balances[account] = current_balance - value;
        _totalSupply -= value;
        emit Transfer(account, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        uint256 current_allowance = _allowances[account][msg.sender];
        require(current_allowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, msg.sender, current_allowance - amount);
    }
}

/*
  Fake MockERC20 proxy.
  Admins can manipulate balances.
  Users can mint for themselves.
*/
contract SelfSufficientERC20 is ERC20 {
    // Simple permissions management.
    mapping(address => bool) admins;
    address owner;
    uint256 max_mint = MAX_MINT;

    uint256 constant MAX_MINT = 1000; // Maximal amount per selfMint transaction.

    function initlialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external onlyOwner {
        require(decimals_ == 0, "ALREADY_INITIALIZED");
        require(_decimals != 0, "ILLEGAL_INIT_VALUE");
        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;
    }

    constructor() {
        admins[msg.sender] = true;
        owner = msg.sender;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "ONLY_ADMIN");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function registerAdmin(address newAdmin) external onlyOwner {
        admins[newAdmin] = true;
    }

    function removeAdmin(address oldAdmin) external onlyOwner {
        require(oldAdmin != owner, "OWNER_MUST_REMAIN_ADMIN");
        admins[oldAdmin] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        admins[newOwner] = true;
        owner = newOwner;
    }

    function adminApproval(
        address fundsOwner,
        address spender,
        uint256 value
    ) external onlyAdmin {
        _approve(fundsOwner, spender, value);
    }

    function setBalance(address account, uint256 amount) external onlyAdmin {
        _totalSupply += amount - _balances[account];
        _balances[account] = amount;
    }

    function resetMaxMint(uint256 newMax) external onlyOwner {
        max_mint = newMax;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}