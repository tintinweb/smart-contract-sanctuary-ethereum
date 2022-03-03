/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Market {
    mapping(address => mapping(uint256 => uint256)) market;

    event Sell(address user,uint256 id,uint256 price);
    event Buy(address user,address seller,uint256 id,uint256 price);

    function sell(address user,uint256 id,uint256 price) public {
        market[user][id] = price;
        emit Sell(user,id,price);
    }

    function buy(address seller,uint256 id) public {
        uint256 price = market[seller][id];
        delete market[seller][id];
        emit Buy(msg.sender,seller, id, price);
    }
}