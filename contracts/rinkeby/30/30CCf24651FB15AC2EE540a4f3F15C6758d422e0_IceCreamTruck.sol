//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IceCreamTruck {
    uint256 numberOfBuyers;
    mapping(address => buyer) buyers;

    enum iceCreamFlavour {
        Chocolate,
        Strawberry,
        Mint_Choc_Chip,
        Vanilla,
        Cookie_Dough
    }
    struct buyer {
        string name;
        uint256 age;
        iceCreamFlavour IceCream;
        uint256 price;
        address buyerAddress;
    }

    function addNewBuyer(
        string memory _name,
        uint256 _age,
        iceCreamFlavour _IceCream,
        uint256 _price
    ) public {
        buyers[msg.sender] = buyer(_name, _age, _IceCream, _price, msg.sender);
        numberOfBuyers++;
    }

    function returnIceCreamBuyerInfo(address _address)
        public
        view
        returns (
            string memory,
            uint256,
            iceCreamFlavour,
            uint256
        )
    {
        return (
            buyers[_address].name,
            buyers[_address].age,
            buyers[_address].IceCream,
            buyers[_address].price
        );
    }
}