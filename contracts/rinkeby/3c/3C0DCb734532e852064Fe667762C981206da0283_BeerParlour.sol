//SPDX-License-Identifier:UNLICENSED

pragma solidity 0.8.7;

contract BeerParlour {
    //uint public minimumAge = 18;
    uint _minimumAge;
    bool public canDrink = false;
    string result = "Young man you cannot drink go home";

    function age(uint minimumAge) external {
        if (minimumAge >= 18) {
            canDrink = true;
            result = "You can drink, Kudos";
        } else {
            canDrink = false;
            result = "Sorry go home you cannot drink";
        }
    }

    function beerStatus() public view returns (string memory) {
        return result;
    }

    function getMinimumAge() public pure returns (uint) {
        uint beerAge = 18;
        return beerAge;
    }
}