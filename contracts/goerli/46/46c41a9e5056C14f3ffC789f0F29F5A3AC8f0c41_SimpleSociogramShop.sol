//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SimpleSociogramShop {
    address payable public owner;

    function initialize() public {
        owner = payable(msg.sender);
    }

    event ProductSold(uint256 content_id, uint256 price, address seller, address buyer);

    function buyContent(uint256 content_id, address payable seller) public payable {
        require(msg.value > 0, "You must send some Ether to buy the content");
        require(seller != msg.sender, "You cannot buy your own content");
        seller.transfer(msg.value);
        emit ProductSold(content_id, msg.value, seller, msg.sender);
    }
}