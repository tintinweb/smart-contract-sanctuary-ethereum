/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TokenSale {
        uint256 public maxAmount;
        mapping(address => uint256) public balances;
        uint256 public maxBuy;
        uint256 tokenPrice;
        event Buy(address indexed _from, uint256 indexed _amount, uint256 _price);
        event Sell(address indexed _from, uint256 indexed _amount);

        constructor(uint256 _maxAmount){
            maxAmount = _maxAmount;
            maxBuy = 100;
            tokenPrice= 0.01 ether;
        }

        function buy1() public payable{
            uint256 soldTokens = msg.value/tokenPrice;
            require(soldTokens < maxBuy);
            require(msg.value > 0);
            require( maxAmount > (soldTokens));
            
            maxAmount -= soldTokens;
            balances[msg.sender] += soldTokens;
            emit Buy(msg.sender, (soldTokens) , tokenPrice );
        }

        function buy2(uint _amount) public payable{
            require(_amount < maxBuy);
            require(msg.value > (_amount*tokenPrice));
            require( maxAmount > _amount);
            
            maxAmount -= _amount;
            balances[msg.sender] += _amount;
            emit Buy(msg.sender, _amount , tokenPrice );
        }

        function sell(uint256 _sellingAmount) public {
            require(balances[msg.sender] > _sellingAmount);
            require(address(this).balance > (_sellingAmount*tokenPrice));

            maxAmount += _sellingAmount;
            balances[msg.sender] -= _sellingAmount;
            payable (msg.sender).transfer(_sellingAmount*tokenPrice);
        }


}