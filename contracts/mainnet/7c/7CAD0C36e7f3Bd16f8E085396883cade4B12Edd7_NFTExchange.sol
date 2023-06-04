// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract NFTExchange {
    mapping(address => Order) private myOrder;

    struct Order {
        address senderNFTContractAddress;
        uint256 senderNFTTokenId;
        address receiverNFTContractAddress;
        uint256 receiverNFTTokenId;
    }

    function createOrder(address _senderNFTContractAddress, uint256 _senderNFTTokenId, address _receiverNFTContractAddress, uint256 _receiverNFTTokenId) public {
        if(IERC721(_senderNFTContractAddress).getApproved(_senderNFTTokenId) != address(this)) revert("NFT you hold is not approve");

        myOrder[msg.sender] =  Order(_senderNFTContractAddress, _senderNFTTokenId, _receiverNFTContractAddress, _receiverNFTTokenId);
    }

    function approveOrder(address _senderNFTContractAddress, uint256 _senderNFTTokenId, address _receiverNFTContractAddress, uint256 _receiverNFTTokenId,address orderSender) public {
        Order memory order = myOrder[orderSender];

        if(order.senderNFTContractAddress == address(0)) revert("Order Not Found");
        if(order.senderNFTContractAddress != _senderNFTContractAddress || order.senderNFTTokenId != _senderNFTTokenId || order.receiverNFTContractAddress != _receiverNFTContractAddress || order.receiverNFTTokenId != _receiverNFTTokenId){
            revert("Order has been Changed");
        }

        IERC721 orderSenderNFT = IERC721(order.senderNFTContractAddress);
        IERC721 orderReceiverNFT = IERC721(order.receiverNFTContractAddress);

        if(orderSenderNFT.ownerOf(order.senderNFTTokenId) != orderSender) revert("Order Registrant does not have this NFT");
        if(orderReceiverNFT.ownerOf(order.receiverNFTTokenId) != msg.sender) revert("You do not have this NFT");

        orderSenderNFT.transferFrom(orderSender, msg.sender, order.senderNFTTokenId);
        orderReceiverNFT.transferFrom(msg.sender, orderSender, order.receiverNFTTokenId);

        delete myOrder[orderSender];
    }

    function closeOrder() public {
        delete myOrder[msg.sender];
    }

    function getOrder(address orderSender) public view returns(Order memory) {
        return myOrder[orderSender];
    }

}

abstract contract IERC721 {
    function getApproved(uint256 tokenId) virtual external view returns (address operator) ;
    function ownerOf(uint256 tokenId) virtual external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) virtual external;

}