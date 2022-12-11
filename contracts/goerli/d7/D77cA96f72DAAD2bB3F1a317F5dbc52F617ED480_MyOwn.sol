// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyOwn {
    enum CoffeeSize {
        Demi,
        Short,
        Tall,
        Grande,
        Venti,
        Trenta
    }
    enum CoffeeType {
        Mocha,
        Frappe,
        Latte,
        Espresso,
        Black
    }
    // initialize to a state variable
    CoffeeSize public coffeeSize;
    CoffeeType public coffeeType;

    // create struct
    struct PlaceOrder {
        address _addr;
        CoffeeSize coffeeSize;
        CoffeeType coffeeType;
    }
    PlaceOrder[] public orders;

    function place(CoffeeSize _size, CoffeeType _type) external {
        // initialize the struct
        PlaceOrder memory newCustomer = PlaceOrder(msg.sender, _size, _type);
        // push to array
        orders.push(newCustomer);
    }

    function read(uint256 _index)
        external
        view
        returns (
            address _addr,
            CoffeeSize,
            CoffeeType
        )
    {
        PlaceOrder storage order = orders[_index];
        return (order._addr, order.coffeeSize, order.coffeeType);
    }
}