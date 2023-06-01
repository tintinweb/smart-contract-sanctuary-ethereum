// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint256  favNum;
    enum favFood {
        Pizza,
        Burger,
        Noodles
    }

    favFood favoriteFood;

    function store(uint256 _favNum) public  {
        favNum = _favNum;
    }

    // pure / view functions
    function retrieve() public view returns (uint256) {
        return favNum;
    }

    function OrderPizza() public {
        favoriteFood = favFood.Pizza;
    }

    function OrderBurger() public{
        favoriteFood = favFood.Burger;
    }

    function OrderNoodles() public {
        favoriteFood = favFood.Noodles;
    }

    function myFavFood() public view returns(favFood){
        return favoriteFood;
    }

}