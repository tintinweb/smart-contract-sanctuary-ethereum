/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.4.24; ////solidity編譯器版本
 

//去除出現負數及除零的可能 確保四則運算的正確性
contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a); //要求a+b後c要>=a 
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b; //要求a要>=b 確保a-b後不會出現負數
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b); //要求a==或者c/a = b
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0); //要除被除數>0 去除除零的可能
        c = a / b;
    }
}
 
//類似Java的interface 為接下來的程式碼定下它的結構
contract ERC20Interface {
    function totalSupply() public constant returns (uint); //所有Token的供應量
    function balanceOf(address tokenOwner) public constant returns (uint balance); //回存tokenOwner持有的Token數量
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining); //回傳spender使用token的數量
    function transfer(address to, uint tokens) public returns (bool success); //輸入希望存款至的地址及希望token數量, 回存一個boolean
    function approve(address spender, uint tokens) public returns (bool success); //sender授權spender可以使用某個token數量 回存一個boolean
    function transferFrom(address from, address to, uint tokens) public returns (bool success); //傳入存款人地址.收款人地址以及token數量, 回存一個boolean
 
    event Transfer(address indexed from, address indexed to, uint tokens); //transfer事件 需要address from, address to及uint tokens
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);//approval事件 需要address tokenOwner, address spender及uint tokens
}
 
//用作接收approval及執行receiveApproval這個function 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//NTUT_Token繼承了ERC20Interface及SafeMath
contract NTUT_Token is ERC20Interface, SafeMath {
    //宣告資料類別
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    mapping(address => uint) balances; //keytype是address valuetype是uint的mapping
    mapping(address => mapping(address => uint)) allowed; //keytype是address, 而valuetype是另一個mapping 內層mapping的keytype是address, valuetype是uint
 
    //建構子
    constructor() public {
        symbol = "NTUT"; //貨幣的簡稱
        name = "NTUT Coin"; //貨幣的名字
        decimals = 18; //ERC20貨幣通常使用18位
        _totalSupply = 100000; //貨幣的總發行量
        balances[0x0dd50C057f7A307D5A992a5C7112246A4dC5C108] = _totalSupply; //在此處使用我的公鑰, 公鑰內的的存款為總發行量
        emit Transfer(address(0), 0x0dd50C057f7A307D5A992a5C7112246A4dC5C108, _totalSupply); //Transfer事件
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)]; //totalSupply扣掉0號地址 回傳貨幣的總發行量
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner]; //回傳adderss tokenOwner內的結餘
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens); //利用safeSub確保sender扣掉希望轉帳的token數量後, sender不會出現負結餘
        balances[to] = safeAdd(balances[to], tokens); //利用safeAdd確保不會出現負數轉帳
        emit Transfer(msg.sender, to, tokens); //Transfer事件
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens; //sender授權spender使用指定token數量
        emit Approval(msg.sender, spender, tokens);//Approval事件
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens); //利用safeSub確保from的地址轉帳指定數量token後不會出現負結餘
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);//from地址授權sender使用指定token數量,並使用safeSub確保不會出現負結餘
        balances[to] = safeAdd(balances[to], tokens); //將token加到to地址 使用safeAdd確保不會加上負數的token
        emit Transfer(from, to, tokens); //Transfer事件
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender]; //tokenOwner授權spender可以使用某個token數量
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens; //sender授權spender可以使用某個token數量
        emit Approval(msg.sender, spender, tokens); //Approval事件
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data); //利用spender的address運行ApproveAndCallFallBack function內的receiveApproval
        return true;
    }
}