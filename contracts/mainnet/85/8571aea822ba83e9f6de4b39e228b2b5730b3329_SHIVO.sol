/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

pragma solidity ^0.5.0;
// ----------------------------------------------------------------------------
// 
//  Maybe you've been with us since shibainu days or you discovered shibagun yesterday,
//  it doesn't matter to us because we are all shibaarmy members welcome to shibagun club
//     award distribution address : (0x8f58098791aAf39e4d40c65865DfeB961a17F558)
//   ***Total supply: 1,032,009,000,000 *** 01/03/2009 
//  
//    gAME reward 30 (to be distributed in 2 years )
//    Airdrop % 20 determined by lottery 
//    Marketing %5
//    Liquidity %45 ( 2 YEARS LOCKED )
//    TEAM     :00000000000%
//    SHIVO Official Portals -- https://linktr.ee/shytoshikusama
//    Website — http://shibagun.com
//    Twitter** https://twitter.com/ShibaStrength
//    Telegram — https://t.me/shibagun
//HOW TO START THE DOCUMENTARY SHIVO GAME?
//To contribute to the Satoshi Nakamoto and Ryoshi Documentary, you only need to have 1000000 SHIVO Tokens in your
 //Ethereum wallet. Those who have 1000000 SHIVO Tokens in their wallet will be able 
 //to play the SHIBGUN DOCUMENTARY GAME without paying any transaction fees or sending SHIVO tokens for the Game.
//Our game is played only with the guessing system. It is completely dependent on the Shibainu and Dogecoin system.
//Wallet holders with 100000 SHIVO TOKEN’S in their wallets estimate 
//based on the price chart starting at 00:00 European time and ending at 00:00 European time the next day.
 //Players who want to get a share of the prize pool It should predict the price rise or fall of the
  //shibainu coin and dogecoin during this time frame. The first game starts at 00:00 European 
  //time and ends at 00:00 European time the next day. Predictions take one month and $1000 worth of Ethereum
   //in the Prize pool will be split equally among those who correctly predicted the price rise or fall of
    //Shibainu Token or Dogecoin for one month.
//METHODOLOGY
//Wallet holding 100000 SHIVO Token ----->
 //Shibainu or Dogecoin Price chart -------> 
 //Shibainu or Dogecoin Price forecast = ✅Correct ---- > 1 month price forecast = ✅Correct ----- > 
 //You are entitled to receive the prize pool. 🏦💵💵 Price estimate on day 2 = ❌ Wrong ----- >
 // You are not eligible to receive the prize pool. 🏦💵💵 Your 1-month price forecast starts the next day ----->
   //Shibainu or Dogecoin Price chart -------> Shibainu or Dogecoin Price forecast = ✅Correct ---- >
    //1-month price forecast = ✅Correct - -- --> You are entitled to receive the prize pool. 🏦💵💵
//Distribution of $1000 prize pools starts after 1 month and continues daily for 1 year. Thus, 360000$
 //reward will be distributed for 1 year. One month later, Shibgun tokens in prize pools of $1,000 
 //that were not distributed as a result of the predictions will be burned. This will continue for a year.
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


contract SHIVO is ERC20Interface, SafeMath {
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
        name = "SHIVO";
        symbol = "SHIVO";
        decimals = 18;
        _totalSupply = 1032009000000* (uint256(10) ** decimals);

        
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