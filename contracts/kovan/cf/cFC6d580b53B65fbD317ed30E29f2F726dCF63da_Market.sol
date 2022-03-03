/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Market {
    uint256 userId;
    uint256 orderId;
    mapping(address => uint256) user;
    mapping(uint256 => mapping(uint256 => uint256)) market;

    event Sell(uint256 id,address user,uint256 tokenId,uint256 price);
    event Buy(uint256 id,address user,uint256 tokenId,uint256 price);

    function sell(uint256 _tokenId,uint256 _price) public {
        uint256 _userId = user[msg.sender];
        if(_userId == 0) {
            _userId = ++userId;
        }
        market[_userId][_tokenId] = _price;
        emit Sell(orderId++,msg.sender,_tokenId,_price);
    }

    function buy(address _seller,uint256 _tokenId) public {
        uint256 _sellId = user[_seller];
        require(_sellId != 0);

        uint256 _price = market[_sellId][_tokenId];
        require(_price != 0);
        
        delete market[_sellId][_tokenId];

        emit Buy(orderId++,msg.sender, _tokenId, _price);
    }
}