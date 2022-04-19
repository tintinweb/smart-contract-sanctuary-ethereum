// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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


contract NFTMarketplaceV1 {
    struct Order {
        address seller;
        address collection;   
        uint256 nftsId;
        address tokenAddress;
        uint256 price;   
    }

    uint256 counterOrder;

    mapping (uint256 => Order) listOrders;

    function getCounterOrder() public view returns (uint256) {
        return counterOrder;
    } 

    function createOrder(address _collection, uint256 _nftsId, address _tokenAddress, uint256 _price) public {
        require(IERC721(_collection).ownerOf(_nftsId) == msg.sender, "NFT only transfer by it's owner");
        require(IERC721(_collection).isApprovedForAll(msg.sender, address(this)), "NFT have to approve for marketplace");
        // delegate call to transfer NFT to nftMarketplace
        IERC721(_collection).transferFrom(msg.sender, address(this), _nftsId);
        // save order to blockchain
        Order memory newOrder = Order(msg.sender, _collection, _nftsId, _tokenAddress, _price);
        listOrders[counterOrder] = newOrder;
        counterOrder++;
    }

    function matchOrder(uint256 _orderId) public {   
    }
}