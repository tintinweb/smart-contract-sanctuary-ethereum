/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Welcome to Harambe.
 
 
██   ██  █████  ██████   █████  ███    ███ ██████  ███████ 
██   ██ ██   ██ ██   ██ ██   ██ ████  ████ ██   ██ ██      
███████ ███████ ██████  ███████ ██ ████ ██ ██████  █████   
██   ██ ██   ██ ██   ██ ██   ██ ██  ██  ██ ██   ██ ██      
██   ██ ██   ██ ██   ██ ██   ██ ██      ██ ██████  ███████ 
                                                           
                                                           
 * Official website: Harambe.cc
 * Make Harambe Alive Again.
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Harambe is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public taxWhitelist;
    address private contractOwner;
    uint256 public taxRate; // Tax rate in percentage
    bool private ownerRenounced;
    bool public taxEnabled;

    constructor() {
        name = "Harambe";
        symbol = "HARAMBE";
        decimals = 18;
        contractOwner = msg.sender;
        _totalSupply = 69_000_000_000_000 * 10**uint256(decimals); // Total supply of 69 trillion tokens
        _balances[msg.sender] = _totalSupply; // Assign all tokens to the contract deployer
        taxWhitelist[msg.sender] = true; // Add the contract deployer to the whitelist
        taxRate = 0; // Initial tax rate is set to 0%. Tax function will be used exclusively to block MEV bots buying at launch.
        ownerRenounced = false;
        taxEnabled = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        if (taxEnabled && !taxWhitelist[sender] && !taxWhitelist[recipient]) {
            uint256 taxAmount = (amount * taxRate) / 100; // Calculate tax amount based on the tax rate
            uint256 transferAmount = amount - taxAmount;

            _balances[sender] -= amount;
            _balances[recipient] += transferAmount;
            _balances[contractOwner] += taxAmount; // Send tax to the owner address

            emit Transfer(sender, recipient, transferAmount);
            emit Transfer(sender, contractOwner, taxAmount);
        } else {
            _balances[sender] -= amount;
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function changeTaxRate(uint256 newTaxRate) public {
        require(!ownerRenounced, "Ownership has been renounced");
        require(msg.sender == contractOwner, "Only the contract owner can change the tax rate");
        require(newTaxRate >= 0 && newTaxRate <= 100, "Tax rate must be between 0 and 100");

        taxRate = newTaxRate;
    }

    function enableTax() public {
        require(!ownerRenounced, "Ownership has been renounced");
        require(msg.sender == contractOwner, "Only the contract owner can enable the tax");
        taxEnabled = true;
    }

    function disableTax() public {
        require(!ownerRenounced, "Ownership has been renounced");
        require(msg.sender == contractOwner, "Only the contract owner can disable the tax");
        taxEnabled = false;
    }

    function addToTaxWhitelist(address[] calldata addresses) external {
        require(!ownerRenounced, "Ownership has been renounced");
        require(msg.sender == contractOwner, "Only the contract owner can add addresses to the tax whitelist");

        for (uint256 i = 0; i < addresses.length; i++) {
            taxWhitelist[addresses[i]] = true;
        }
    }

    function removeFromTaxWhitelist(address[] calldata addresses) external {
        require(!ownerRenounced, "Ownership has been renounced");
        require(msg.sender == contractOwner, "Only the contract owner can remove addresses from the tax whitelist");

        for (uint256 i = 0; i < addresses.length; i++) {
            taxWhitelist[addresses[i]] = false;
        }
    }

    function renounceOwnership() public {
        require(msg.sender == contractOwner, "Only the contract owner can renounce ownership");
        ownerRenounced = true;
    }
}