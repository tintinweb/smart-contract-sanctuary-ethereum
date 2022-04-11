pragma solidity ^0.4.17;

import './TestToken.sol';


contract Reserve {
    using SafeMath for uint;
 
    TestToken public tokenAddress ;
    address owner;
    uint buyRate;
    uint sellRate;
    
    function Reserve(address token) public{
        owner = msg.sender;
        tokenAddress = TestToken(token);
        buyRate = 100;
        sellRate = 120;
    }

    function setExchangeRates(uint buy, uint16 sell) public {
        require(msg.sender == owner && buy != 0 && sell != 0);
        require(sell >= buy);
        buyRate = buy;
        sellRate = sell;
    }
    
    function getExchangeRate(bool isBuy,uint srcAmount) public view returns (uint){
        if(isBuy){
            return srcAmount.mul(buyRate);
        }else{
            return srcAmount.div(sellRate);
        }
    }

    function sell(uint srcAmount) public{
        require(srcAmount > 0);
        uint allowance = tokenAddress.allowance(msg.sender, this);
        require(allowance >= srcAmount);
        uint rt = getExchangeRate(false,srcAmount);
        tokenAddress.transferFrom(msg.sender,this,srcAmount);
        msg.sender.transfer(rt);
        
    }

    function buy() public payable {
        require(msg.value > 0);
        uint rt = getExchangeRate(true, msg.value);
        require(tokenAddress.balanceOf(this) >= rt);
        tokenAddress.transfer(msg.sender, rt);
    }

    function getPool() public view returns (uint){
        return tokenAddress.balanceOf(this);
    }

    function getBalance() public view returns (uint){
        return this.balance;
    }

    function withdrawAll() public{
        require(msg.sender == owner);
        msg.sender.transfer(this.balance);
    }
}