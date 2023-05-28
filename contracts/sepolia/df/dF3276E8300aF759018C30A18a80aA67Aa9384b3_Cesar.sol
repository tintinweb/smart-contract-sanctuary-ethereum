// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import"./IERC20.sol";
import"./SafeMath.sol";
contract Cesar is IERC20 {
    using SafeMath for uint256;

    string private _name = "Cesar";
    string private _symbol = "CSR";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 500000000000000 * (10**uint256(_decimals));
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
        uint256 private _taxPercentage = 1; 
    
        mapping(address => bool) private _blacklist;
    

    address private _owner;
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call this function");
        _;
    }
    
    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(!_blacklist[msg.sender], "Sender is in the blacklist");
        require(!_blacklist[recipient], "Recipient is in the blacklist");

        uint256 taxAmount = amount.mul(_taxPercentage).div(100);
        uint256 transferAmount = amount.sub(taxAmount);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);
        _balances[_owner] = _balances[_owner].add(taxAmount);

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, _owner, taxAmount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(!_blacklist[sender], "Sender is in the blacklist");
        require(!_blacklist[recipient], "Recipient is in the blacklist");

        uint256 taxAmount = amount.mul(_taxPercentage).div(100);
        uint256 transferAmount = amount.sub(taxAmount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);
        _balances[_owner] = _balances[_owner].add(taxAmount);

        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _owner, taxAmount);
        emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedAmount) public returns (bool) {
        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(addedAmount);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedAmount) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedAmount, "Decreased allowance below zero");
        _allowances[msg.sender][spender] = currentAllowance.sub(subtractedAmount);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
    
    function updateTaxPercentage(uint256 newPercentage) public onlyOwner {
        _taxPercentage = newPercentage;
    }
    
    function addToBlacklist(address account) public onlyOwner {
        _blacklist[account] = true;
    }
    
    function removeFromBlacklist(address account) public onlyOwner {
        _blacklist[account] = false;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        _owner = newOwner;
    }
}