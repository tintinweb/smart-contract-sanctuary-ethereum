//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";
contract Sample is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    function name() external view override returns (string memory) {
        return _name;
    }
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
    uint256 private _totalSupply;
    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowance;
    constructor() {
        _balance[msg.sender] = 1000000;
        _totalSupply = 10000000;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    } 
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        address spender = msg.sender;
        _transfer(sender, recipient, amount);
        _allowance[sender][spender] -= amount;
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowance[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) public returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: amount should greater than zero");
        require(_balance[from] >= amount, "ERC20: transfer amount exceeds balance");
        _balance[from] -= amount;
        _balance[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    modifier onlyOwner() {
        _;
    }
    function mint(address receiver, uint256 amount) external onlyOwner() {
        require(receiver != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "ERC20: amount should geater than zero");
        _totalSupply += amount;
        _balance[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
    }
    function burn(uint256 amount) external onlyOwner() {
        require(_balance[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        require(amount > 0, "ERC20: amount should greater than zero");
        _balance[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}