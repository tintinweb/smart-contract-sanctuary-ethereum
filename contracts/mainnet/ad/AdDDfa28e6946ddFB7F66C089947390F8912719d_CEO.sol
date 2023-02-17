/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

pragma solidity ^0.5.17;
// ----------------------------------------------------------------------------
//                        CEOINU THE FLOKI KILLER 
//  Maybe you've been with us since flokitoken days or you discovered CEOINU yesterday,
//  it doesn't matter to us because we are all CEOarmy members welcome to Ceoinu club
//     award distribution address : (0x8f58098791aAf39e4d40c65865DfeB961a17F558)
//   ***Total supply: 1,000,000,000,000 ***
//    I AM RYOFLO  
//    burn  %50
//    launchpad %35 
//    Liquidity %15 ( locked for &&& Year)
//    TEAM     :00000000000%
//    CEOİNU TOKEN  Official Portals -- https://linktr.ee/shytoshikusama
//  
//    Twitter** https://twitter.com/ceoinutoken
//    Telegram — https://t.me/ceoinutheflokikiller
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract CEO is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "CEOINU";
        symbol = "CEO";
        decimals = 18;
        _totalSupply = 1000000000000* (uint256(10) ** decimals);

        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}