/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

pragma solidity ^0.4.24; // Solidity編譯器版本
 

// 確保加減乘除不會出現負數及取以0的情況
contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a); // 確保 a + b = c >= a 
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b; // 確保 a >= b 及 a - b > 0
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b); // 確保 a == b OR c / a == b
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0); // 確保不會出現除0的情況
        c = a / b;
    }
}
 
// ERC20 的 Interface
contract ERC20Interface {
    function totalSupply() public constant returns (uint); // Token 的總供應量
    function balanceOf(address tokenOwner) public constant returns (uint balance); // Return tokenOwner 持有的 Token 數量
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining); // Return spender 使用 token 的數量
    function transfer(address to, uint tokens) public returns (bool success); // Input 收款人地址 及 token 數量, Return boolean 成功與否
    function approve(address spender, uint tokens) public returns (bool success); // Sender 授權 spender 可以使用指定 token 數量, Return boolean 成功與否
    function transferFrom(address from, address to, uint tokens) public returns (bool success); // Input 存款人地址. 收款人地址 以及 token數量, Return boolean 成功與否
 
    event Transfer(address indexed from, address indexed to, uint tokens); // Transfer -> Input 存款人地址. 收款人地址 以及 token數量
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);// Approval -> Input token 持有人地址. spender地址 以及 token數量
}
 
// 用作接收 approval 及 執行 receiveApproval 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
// HNT_Coin 繼承 ERC20Interface 及 SafeMath
contract HNT_Coin is ERC20Interface, SafeMath {
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    
    mapping(address => uint) balances; //keytype是address valuetype是uint的mapping
    mapping(address => mapping(address => uint)) allowed; //keytype是address, 而valuetype是另一個mapping 內層mapping的keytype是address, valuetype是uint
 
    // 建構子
    constructor() public {
        symbol = "HNT"; // 貨幣的簡稱
        name = "HNT Coin"; // 貨幣的名字
        decimals = 18; // ERC20 貨幣 18位
        _totalSupply = 100000; // 貨幣的總發行量
        balances[0xd0F275335874F32b02f46641EBD0B77FAa0D0052] = _totalSupply;
        emit Transfer(address(0), 0xd0F275335874F32b02f46641EBD0B77FAa0D0052, _totalSupply); // Transfer
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)]; //totalSupply 扣掉 0 號地址 Return 貨幣的總發行量
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner]; //Return adderss tokenOwner 內的結餘
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens); // 呼叫 safeSub 確保 sender 扣掉希望轉帳的 token 數量後, sender 不會出現負結餘
        balances[to] = safeAdd(balances[to], tokens); // 呼叫 safeAdd 確保不會出現負數轉帳
        emit Transfer(msg.sender, to, tokens); // Transfer
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens; // sender 授權 spender 使用指定 token 數量
        emit Approval(msg.sender, spender, tokens); // Approval
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens); // 呼叫 safeSub 確保 from 的地址轉帳指定數量 token 後不會出現負結餘
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);// from 授權 sender 使用指定 token數量, 並呼叫 safeSub 確保不會出現負結餘
        balances[to] = safeAdd(balances[to], tokens); // 將 token 加到 to 地址, 呼叫 safeAdd 確保不會加上負數的 token
        emit Transfer(from, to, tokens); // Transfer 
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender]; //tokenOwner 授權 spender 可以使用某個 token 數量
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens; // sender 授權 spender 可以使用某個 token 數量
        emit Approval(msg.sender, spender, tokens); // Approval 
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data); // 利用 spender 的 address 運行 ApproveAndCallFallBack function 內的 receiveApproval
        return true;
    }
}