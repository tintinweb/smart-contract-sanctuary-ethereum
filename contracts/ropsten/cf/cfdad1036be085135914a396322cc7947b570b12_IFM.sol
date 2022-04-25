/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

pragma solidity ^0.8.13; //SPDX-License-Identifier: UNLICENSED

contract IFM{
    //這裡定義token的全名、縮寫、精度大小以及總發行量
    string public name; 
    string public symbol;
    uint8 public decimals;
    uint256 totalSupply_;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);   //當使用者(owner)被授權時，執行從一個帳戶提領token並發送到另個帳戶
    event Transfer(address indexed from, address indexed to, uint tokens);  //owner傳送token到指定帳戶
    event Mint(address indexed from, uint tokens);
    event Burn(address indexed to, uint tokens);

    mapping(address => uint256) balances;   //每個帳戶位置對應的餘額
    mapping(address => mapping(address => uint256)) allowed;    //每個授權帳戶位置能提領的總金額

    using SafeMath for uint256; //使用SafeMath來預防溢位
    
    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, uint256 total){
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;   //小數點2位
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }
    
    function totalSupply() public view returns (uint256){   //回傳總發行量
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint){  //回傳帳戶餘額
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool){  //只有token的owner才能發送token給其他人
        require(numTokens <= balances[msg.sender]);  //判斷欲發送的token數有沒有在owner帳戶餘額內
        balances[msg.sender] = balances[msg.sender].sub(numTokens);  //若有，owner帳戶餘額扣除欲發送的token數
        balances[receiver] = balances[receiver].add(numTokens);  //接收者帳戶餘額加上被發送的token數
        emit Transfer(msg.sender, receiver, numTokens);  //執行Transer event
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool){   //owner授權指定帳戶從owner的帳戶提領token
        allowed[msg.sender][delegate] = numTokens;  //owner授權的指定帳戶所能提領的token數
        emit Approval(msg.sender, delegate, numTokens); //執行Approval event
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint){ //回傳目前被owner授權的帳戶所提領的token數
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool){  //授權指定帳戶提領owner的token並發送到第三方帳戶
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);   //判斷欲發送的token數有沒有在指定帳戶餘額內

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens); //指定帳戶的餘額扣除欲發送的token數
        balances[buyer] = balances[buyer].add(numTokens);   //第三方帳戶餘額加上被發送的token數
        emit Transfer(owner, buyer, numTokens); //執行Transfer event
        return true;
    }

    function mint(address _account, uint _amount) public{   //增加個人token，增加totalSupply的token
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Mint(_account, _amount);
    }

    function burn(address _account, uint _amount) public{   //減少個人token，減少totalSupply的token
        totalSupply_ = totalSupply_.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Burn(_account, _amount);
    }
}

library SafeMath{
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b <= a); //驗證參數是否正確
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}