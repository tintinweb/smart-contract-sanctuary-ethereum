/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

pragma solidity ^0.5.0;
// ----------------------------------------------------------------------------
/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// 
//  Maybe you've been with us since shibainu days or you discovered shibagun yesterday,
//  it doesn't matter to us because we are all shibaarmy members welcome to shibagun club
//     award distribution address : ()
//   ***Total supply: 100,000,000 ***
//   
//    prize % 25 burn  % 25
//    Marketing %5
//    Liquidity %45 ( locked for a year)
//    TEAM     :00000000000%
//    Shibagun Official Portals -- https://linktr.ee/shytoshikusama
//    Website — http://shibagun.com
//    Twitter** https://twitter.com/ShibaStrength
//    Telegram — https://t.me/shibagun
//
// --------------------------
//-------------------------------------
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


contract shibagun is ERC20Interface, SafeMath {
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
        name = "shibagun";
        symbol = "shibgun";
        decimals = 18;
        _totalSupply = 100000000* (uint256(10) ** decimals);

        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0xaa9186B9953bA0153F276bf87381F2F6Ca0423F4), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0xaa9186B9953bA0153F276bf87381F2F6Ca0423F4)];
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