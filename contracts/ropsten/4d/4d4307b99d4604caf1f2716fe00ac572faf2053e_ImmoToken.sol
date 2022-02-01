/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

pragma solidity ^0.5.0;

// 'ImmoToken' token contract

// Deployed to  : 0x83fCaf8c37CE6F555a89D8A2366f6f81ccf530d2
// Symbol       : IMT
// Name         : ImmoToken
// Total supply : 1000000
// Decimals     : 18

// Contract Author: Bernhard Gotthart

// ----------------------------------------------------

/*
REAL ASSET TOKEN CONTRACT (EXAMPLE)
Description                             Reference information
Rental property, 4 bedroom house        Link to property description (floor plans)
Address of property                     Vienna, AUSTRIA (link to address, ie.google map)
Net Annual Income                       $24,000 USD
Proof of Title                          Deed registration # 0001234 (link)
Insurance certificate                   ABC Insurance #0002022 (link)
Owner(s)                                Names and address's
Purchase price                          $500,000 USD
Date of purchase                        April 1st, 1990
Current Value (January 2022)            $1,000,000 USD
Property appraisal certificate          Link to certificate
Owners social media profile             LinkedIn
Notarization certificate                link to notarization
Token name                              ImmoToken
Token value                             Each token represents 0.0001% of total asset
Initial token price                     2500 ImmoTokens = 1ETH
Total token distribution                1,000,000
Dividends                               Not applicable
Voting Rights                           Not applicable
Date                                    January 1st, 2022
Owner(s) signature 
*/

// ----------------------------------------------------

//Interface des ERC-20 konformen Tokens
contract ERC20Interface {
    //returns total supply of the token created
    function totalSupply() public view returns (uint);
    
    //returns token balance for the supplied address
    function balanceOf(address tokenOwner) public view returns (uint balance);
    
    //this function will cancle a transaction of the user doesn't have sufficient balance
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    
    //allows the contract owner to give tokens to other users
    function transfer(address to, uint tokens) public returns (bool success);
    
    //this function checks the transaction against the total supply of tokens to make sure that there are none missing or extra.
    function approve(address spender, uint tokens) public returns (bool success);
    
    //this function is used to support automated transfers to a specific account
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    //Event raised on a transfer
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    //event raised on a approval
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
} // ERC20Interface


// SafeMath library wrappers over solidity's arithmetic operations with added overflow checks
contract SafeMath {
    //the safe function for adding
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    } //safeAdd
    
    //the safe function for subtration
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    } //safeSub
    
    //the safe function for multiplication
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    } //safeMul
    
    //the function for division
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    } //safeDiv
} //SafeMath



//the new token smart contract
//erbt von ERC20Interface und SafeMath
contract ImmoToken is ERC20Interface, SafeMath {
    //local Variables
    //token name
    string public name;
    
    //token sybol (3 characters)
    string public symbol;
    
    //the token's precision (number of decimal places)
    uint8 public decimals;
    
    //the total supply of the new token
    uint256 public _tokenSupply;
    
    //mappings for account balances and allowed
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    //the constructor for our smart contract
    //this function runs ONCE during deployment
    constructor() public {
        name = "IMT";
        symbol = "ImmoToken";
        decimals = 18;
        _tokenSupply = 1000000000000000000000000;
        
        balances[msg.sender] = _tokenSupply;
        emit Transfer(address(0), msg.sender, _tokenSupply);
    } //constructor
    
    //returns the total supply of the token created
    function totalSupply() public view returns (uint) {
        return _tokenSupply - balances[address(0)];
    } //totalSupply
    
    //returns the token balance for the supplied address
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    } //balanceOf
    
    //this function will cancle a transaction if the user does not have sufficient balance
    function allowance (address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    } //allowance
    
    //this function checks the transaction against the total supply of tokens to make sure that there are none missing or extra
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    } //approve
    
    //allows the contrat owner to give tokens to other users
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        
        emit Transfer(msg.sender, to, tokens);
        return true;
    } //transfer
    
    //this function is used to support automated transfers to a specific account
    function transferFrom (address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        
        emit Transfer(from, to, tokens);
        return true;
    } //transferFrom
    
} //ImmoToken