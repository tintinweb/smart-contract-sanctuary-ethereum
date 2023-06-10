// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./IERC20.sol";
import "./SafeMath.sol";

contract Lumalee is IERC20 {
    using SafeMath for uint256;

    string private _name = "LUMALEE";
    string private _symbol = "LUMA";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 420000000000000 * (10**uint256(_decimals));

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private _owner;
    mapping(address => bool) private _excludedFees;
    mapping(address => bool) private _excludedRewards;
    bool private _antiBotEnabled;
    mapping(address => bool) private _blacklist;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call this function");
        _;
    }

    modifier antiBotCheck(address sender, address recipient) {
        require(!_antiBotEnabled || (!_blacklist[sender] && !_blacklist[recipient]), "Anti-bot check failed");
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

    function transfer(address recipient, uint256 amount) public override antiBotCheck(msg.sender, recipient) returns (bool) {
        require(amount > 0, "Amount must be greater than zero");

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override antiBotCheck(sender, recipient) returns (bool) {
        require(amount > 0, "Amount must be greater than zero");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);

        emit Transfer(sender, recipient, amount);
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

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        _owner = newOwner;
    }

    function excludeFromFee(address account) public onlyOwner {
        _excludedFees[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _excludedFees[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _excludedFees[account];
    }

    function excludeFromReward(address account) public onlyOwner {
        _excludedRewards[account] = true;
    }

    function includeInReward(address account) public onlyOwner {
        _excludedRewards[account] = false;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _excludedRewards[account];
    }

    function enableAntiBot() public onlyOwner {
        _antiBotEnabled = true;
    }

    function disableAntiBot() public onlyOwner {
        _antiBotEnabled = false;
    }

    function addToBlacklist(address account) public onlyOwner {
        _blacklist[account] = true;
    }

    function removeFromBlacklist(address account) public onlyOwner {
        _blacklist[account] = false;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getContractFunctions() public pure returns (string memory) {
        return
            "name(), symbol(), decimals(), totalSupply(), balanceOf(), transfer(), transferFrom(), approve(), allowance(), increaseAllowance(), decreaseAllowance(), transferOwnership(), excludeFromFee(), includeInFee(), isExcludedFromFee(), excludeFromReward(), includeInReward(), isExcludedFromReward(), enableAntiBot(), disableAntiBot(), addToBlacklist(), removeFromBlacklist(), isBlacklisted(), getOwner(), getContractFunctions()";
    }
}