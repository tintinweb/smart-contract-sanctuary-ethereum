// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract NFTMarketplaceV2 {
    struct Order {
        address seller;
        address collection;   
        uint256 nftsId;
        address tokenAddress;
        uint256 price;   
    }

    uint256 counterOrder;
    mapping (uint256 => Order) listOrders;
    address treasury;
    uint256 fee;

    function getCounterOrder() public view returns (uint256) {
        return counterOrder;
    } 

    function createOrder(address _collection, uint256 _nftsId, address _tokenAddress, uint256 _price) public {
        require(IERC721(_collection).ownerOf(_nftsId) == msg.sender, "NFT only transfer by it's owner");
        require(IERC721(_collection).isApprovedForAll(msg.sender, address(this)), "NFT have to approve for marketplace");
        IERC721(_collection).transferFrom(msg.sender, address(this), _nftsId);
        Order memory newOrder = Order(msg.sender, _collection, _nftsId, _tokenAddress, _price);
        listOrders[counterOrder] = newOrder;
        counterOrder++;
    }

    function addTreasury(address _treasuryAddress) public {
        treasury = _treasuryAddress;
    }

    function getTreasury() view public returns (address){
        return treasury;
    }

    function setFee(uint256 _fee) public {
        fee = _fee;
    }

    function getFee() view public returns (uint256){
        return fee;
    }

    function isOrderExists(uint256 key) public view returns (bool) {
        if(listOrders[key].nftsId != 0) {
            return true;
        } 
        return false;
    }

    function matchOrder(uint256 _orderId) public {   
        require(isOrderExists(_orderId), "Order is not existing!");    
        Order memory currentOrder = listOrders[_orderId];  
        require(IERC20(currentOrder.tokenAddress).allowance(msg.sender, address(this)) != 0, 'Token have to approve for marketplace');
        require(IERC20(currentOrder.tokenAddress).balanceOf(msg.sender) >= currentOrder.price, "Buyer's balance have to greater than or equal nft'price");
        IERC721(currentOrder.collection).transferFrom(address(this), msg.sender, currentOrder.nftsId);
        IERC20(currentOrder.tokenAddress).transferFrom(msg.sender, treasury, (currentOrder.price * (100 + fee) / 100));
        IERC20(currentOrder.tokenAddress).transferFrom(treasury, currentOrder.seller, (currentOrder.price * (100 - fee) / 100));
        listOrders[_orderId].nftsId = 0;
    }
}