/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20Basic {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public constant NAME = "ERC20Basic";
    string public constant SYMBOL = "ERC";
    uint8 public constant DECIMALS = 2;
    
    address public immutable _owner;

    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    uint256 internal totalSupply_ = 100000;

    modifier onlyOwner {
      require(msg.sender == _owner, "Only owner allowed");
      _;
    }

    constructor() {
        _owner = msg.sender;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(receiver != address(0), "ERC20: transfer to the zero address is not allowed");
        require(numTokens <= balances[msg.sender], "ERC20: transfer amount exceeds balance");
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address to, uint256 numTokens) public returns (bool) {
        require(to != address(0), "ERC20: approve to the zero address is not allowed");
        allowed[msg.sender][to] = numTokens;
        emit Approval(msg.sender, to, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address from, address to, uint256 numTokens) public returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address is not allowed");
        require(numTokens <= balances[from], "ERC20: transfer amount exceeds balance");
        require(numTokens <= allowed[from][msg.sender], "ERC20: transfer amount exceeds allowance");

        allowed[from][msg.sender] = allowed[from][msg.sender]-numTokens;
        balances[from] = balances[from]-numTokens;
        balances[to] = balances[to]+numTokens;
        emit Transfer(from, to, numTokens);
        return true;
    }

    function burn(address account, uint256 amount) public onlyOwner returns (bool) {
        require(account != address(0), "ERC20: burn from the zero address is not allowed");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - amount;
        }
        totalSupply_ = totalSupply_ - amount;

        emit Transfer(account, address(0), amount);
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address is not allowed");
        totalSupply_ = totalSupply_ + amount;
        balances[account] = balances[account] + amount;
        emit Transfer(address(0), account, amount);
        return true;
    }
}