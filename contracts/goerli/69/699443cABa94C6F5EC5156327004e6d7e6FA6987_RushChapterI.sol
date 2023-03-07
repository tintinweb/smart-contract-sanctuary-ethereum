// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract RushChapterI {

    enum Dish {
        ICE_TEA, MARS, LION, FANTA, COCA_COLA
    }

    uint8 constant MAX_DISHES = 42;

    Dish public dishes;
    mapping(Dish => uint8) public dishQuantity;
    uint8 public currentQuantity;

    function getDish(Dish _dish, uint8 _quantity) public returns (Dish, uint8, uint8) {
        require(dishQuantity[_dish] >= _quantity, "Not enough dishes, strangly enough you can reload yourself!");
        dishQuantity[_dish] -= _quantity;
        currentQuantity -= _quantity;
        return (_dish, _quantity, dishQuantity[_dish]);
    }

    function fillDish(Dish _dish, uint8 _quantity) public returns (uint8, uint8) {
        uint8 addedQuantity = _quantity;
        if (currentQuantity + addedQuantity > 42)
          addedQuantity = MAX_DISHES - currentQuantity;
        dishQuantity[_dish] += addedQuantity;
        currentQuantity += addedQuantity;
        return (dishQuantity[_dish], addedQuantity);
    }
}