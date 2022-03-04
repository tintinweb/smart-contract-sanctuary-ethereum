/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Market {
    mapping(address => mapping(uint256 => uint256)) public market;

    event Sell(address user,uint256 tokenId,uint256 price);
    event Buy(address user,address seller,uint256 tokenId,uint256 price);

    function sell(uint256 _tokenId,uint256 _price) public {
        market[msg.sender][_tokenId] = _price;
        // 转移ERC721
        emit Sell(msg.sender,_tokenId,_price);
    }

    function buy(address _seller,uint256 _tokenId) public {
        uint256 _price = market[_seller][_tokenId];
        require(_price != 0,"price != 0");

        delete market[_seller][_tokenId];
        // 转移ERC721
        emit Buy(msg.sender,_seller, _tokenId, _price);
    }
}