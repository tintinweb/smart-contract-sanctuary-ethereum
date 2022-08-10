// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ShopEvent{


event ShopCreated(
    uint256 indexed shopId,
    address indexed shopOwner,
    address indexed shop
);

constructor(){

}

function emitShopCreated(uint256 shopId, address shopOwner, address shop) external {
    emit ShopCreated(shopId, shopOwner, shop);
} 

}