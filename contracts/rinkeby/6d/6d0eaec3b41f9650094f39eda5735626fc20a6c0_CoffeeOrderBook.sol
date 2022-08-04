//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import './Cook.sol';

interface IShopList {
    function viewList() external view returns (string memory);
}

contract CoffeeOrderBook is Cook {

    string shopList;

    constructor() {
        super;
    }

    function returnOwner() public view returns (address) {
        return(cook);
    }

    function order() public payable {
        require(msg.value >= 59000 gwei, "Please pay atleast 1 buck");
        cook.transfer(msg.value);
    }

    function getShopList(address _shopList) external onlyCook {
        shopList = IShopList(_shopList).viewList();
    }

    function viewShopList() public onlyCook view returns (string memory) {
        return shopList;
    }
}