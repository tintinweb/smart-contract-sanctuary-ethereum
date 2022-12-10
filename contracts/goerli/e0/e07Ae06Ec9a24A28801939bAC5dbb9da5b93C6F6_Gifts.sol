// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Roles.sol";

contract Gifts is Roleable {
    struct GiftData {
        address sender;
        uint256 amount;
        string timestamp;
        string name;
        string description;
        uint256 price;
    }

    mapping(string => GiftData) public gifts;

    constructor() {
        owner = msg.sender;
    }

    function createGift(
        string memory _id,
        address _sender,
        uint256 _amount,
        string memory _name,
        string memory _description,
        uint256 _price,
        string memory _timestamp
    ) public onlyOwnerOrAdmin {
        gifts[_id] = GiftData({
            sender: msg.sender,
            amount: _amount,
            timestamp: _timestamp,
            name: _name,
            description: _description,
            price: _price
        });
    }

    // function updateGift(
    //     string memory _id,
    //     uint256 _amount,
    //     string memory _name,
    //     string memory _description,
    //     uint256 _price,
    //     string memory _timestamp
    // ) public onlyAdminOrManager {
    //     gifts[_id].amount = _amount;
    //     gifts[_id].name = _name;
    //     gifts[_id].description = _description;
    //     gifts[_id].price = _price;
    //     gifts[_id].timestamp = _timestamp;
    // }

    function removeGift(string memory _id) public onlyAdmin {
        delete gifts[_id];
    }
}