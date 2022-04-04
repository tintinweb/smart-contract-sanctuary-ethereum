/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract AndreasContract is ERC20Interface {
    address owner;
    string public name;
    string public symbol;
    uint8 public decimals;
     
    uint public _totalSupply;

    // balance of my coin
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Received(address, uint, string);

    constructor() {
        owner = msg.sender;
        name = "AndreasToken";
        symbol = "ATKN";
        decimals = 18;        
        // token's total supply
        _totalSupply = 100 * 10 ** decimals;
        balances[owner] = _totalSupply;

        //add some ether to the contract
        emit Transfer(owner, msg.sender, _totalSupply);
    }
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >=a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <=a); 
        c = a - b;
    }
    
     function safeMul(uint a, uint b) public pure returns (uint c) {
         c = a * b;
         require(a == 0 || c/a == b); 
     }

     function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a/b;
     }
    // Returns the total token supply
    function totalSupply() public override view returns (uint)  {
        return _totalSupply;
    }

    // Returns the account balance of my coin of another account with address 'tokenOwner' 
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    // Returns the amount which 'spender' is allowed to withdraw from 'tokenOwner'.
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    // Allows 'spender' to withdraw from your account multiple times, up to the value.
    // If this function is called again it overwrites the current allowance with 'tokens'.
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // Transfers the 'tokens' amount of tokens to address 'to' and MUST fire the 'Transfer' event.
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // Transfers 'tokens' amount of tokens from address 'from' to  address 'to' and MUST fire the 'Transfer' event.
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // Deposits ether to contract's balance.
    function deposit() public payable {
        // address(this).balance += msg.value;
    }

    // Get contract's ether balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    //Get ether balance of an account
    function getCallersEther() public view returns (uint) {
        return address(msg.sender).balance;
    }

    // Callback function that accepts plain Ether transfers i.e for every call with empty calldata.
    receive() external payable {
        emit Received(msg.sender, msg.value, "Receive was called!");
    }

    // This can be called by the contract's owner, mints 'amount' tokens, adding them to the recipient's balance.
    function mint(address recipient, uint amount) public returns (bool success) {
        require(recipient != address(0), "The recipient must be the owner");
        amount *=  10 ** decimals;
        _totalSupply = safeAdd(_totalSupply, amount);

        // uint etherAmount = (amount * address(msg.sender).balance) / _totalSupply;
        balances[recipient] = safeAdd(balances[recipient], amount);
        
        emit Transfer(owner, recipient, amount);
        return true;
    }

    // This burns the amount of the sender's token balance, sending the ether proportionately corresponding to the burned tokens to recipient.
    function burn(address payable account, uint amount) public returns (uint r) {
        require(account != address(0), "Burn from the zero address is not allowed");
        require(balanceOf(account) >= amount, "Insuffucient balance$$$");
        amount *= 10 ** decimals;
        uint etherBalance = address(this).balance;

        balances[account] = safeSub(balances[account], amount);
        _totalSupply -= amount;
        
        uint etherAmount = (amount * etherBalance) / _totalSupply;
        //send ether to recipient - use 'call' function to make the 'burn' method vulnerable to reentrancy attacks.
        account.call{value : etherAmount}("");
        emit Transfer(msg.sender, account, etherAmount);   

        r = etherAmount;
        return r;
    }
}