/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function isApprovedOrOwner (address _spender, uint256 _tokenId) external view returns (bool);
}

contract marketNft {
    address public erc20Token;
    address public erc721Token;

    event buy(address _buyer, address _seller, uint256 _tokenId,uint256 _price,uint256 _time);
    event add(address _seller, address _to, uint256 _tokenId);

    struct infoItem {
        uint256 itemId;
        uint256 tokenId;
        address seller;
        address spender;
        uint256 price;
        uint256 time;
        bool status;
    }

    infoItem[] _infoItem;

    constructor(address _erc20Token, address _erc721Token) {
        erc20Token = _erc20Token;
        erc721Token = _erc721Token;
    }
    
    //-----------------------------Market
    function addToMarket(uint256 _tokenId, uint256 _price) public {
        require(_price > 0, "MARKET: price must be unsigned int");
        address owner = IERC721(erc721Token).ownerOf(_tokenId);
        require(msg.sender == owner, "MARKET: You are not owner");
        IERC721(erc721Token).transferFrom(owner, address(this), _tokenId);
        infoItem memory nftInfo;
        nftInfo.tokenId = _tokenId;
        nftInfo.seller = msg.sender;
        nftInfo.price = _price;
        nftInfo.itemId = _infoItem.length;
        nftInfo.status = true;
        _infoItem.push(nftInfo);
        emit add(msg.sender, address(this), _tokenId);
    }

    function listItems() public view returns(infoItem[] memory) {
        return _infoItem;
    }

    function buyNft(uint256 _itemId) public {
        require(itemExit(_itemId), "MARKET: item is not in the market.");
        infoItem memory item =  _infoItem[_itemId];
        IERC20(erc20Token).transferFrom(msg.sender, item.seller , item.price);      
        IERC721(erc721Token).transferFrom(address(this), msg.sender, item.tokenId);
        _infoItem[_itemId].status = false;
        _infoItem[_itemId].time = block.timestamp;
        emit buy(msg.sender, item.seller, item.tokenId, item.price, _infoItem[_itemId].time);
    }

    function itemExit(uint256 _itemId) public view returns(bool) {
        for (uint256 i = 0; i < _infoItem.length; i++) {
            if (_infoItem[i].itemId == _itemId && _infoItem[i].status == true) return true;
        }
        return false;
    }

    function itemPrice(uint256 _itemId) public view returns(uint256) {
        require(itemExit(_itemId), "MARKET: item is not in the market.");
        return _infoItem[_itemId].price;
    }
}