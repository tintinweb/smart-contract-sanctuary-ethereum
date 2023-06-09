/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SolarEnergyMarket {
    struct EnergyOffer {
        address seller;
        uint256 price;
        uint256 availableQuantity;
    }

    mapping(address => EnergyOffer) public energyOffers;

    event EnergyOfferCreated(address indexed seller, uint256 price, uint256 availableQuantity);
    event EnergySold(address indexed seller, address indexed buyer, uint256 quantity);

    function createEnergyOffer(uint256 _price, uint256 _quantity) external {
        require(_price > 0, "Price must be greater than zero");
        require(_quantity > 0, "Quantity must be greater than zero");
        require(energyOffers[msg.sender].seller == address(0), "Seller can only have one active offer");

        energyOffers[msg.sender] = EnergyOffer(msg.sender, _price, _quantity);
        emit EnergyOfferCreated(msg.sender, _price, _quantity);
    }

    function buyEnergy(address _seller, uint256 _quantity) external payable {
        require(energyOffers[_seller].seller != address(0), "Seller does not have an active offer");
        require(energyOffers[_seller].availableQuantity >= _quantity, "Insufficient energy available");
        require(msg.value == energyOffers[_seller].price * _quantity, "Incorrect payment amount");

        energyOffers[_seller].availableQuantity -= _quantity;
        emit EnergySold(_seller, msg.sender, _quantity);
    }
}