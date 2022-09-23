/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.0;

contract Food {

    uint yesPizza = 0;
    uint noPizza = 0;

    uint yesBurger = 0;
    uint noBurger = 0;

    function pizzaUp () public returns (uint) {
        yesPizza = yesPizza + 1;
        return yesPizza;
    }

    function pizzaDown () public returns (uint) {
        noPizza = noPizza + 1;
        return noPizza;
    }

    function burgerUp () public returns (uint) {
        yesBurger = yesBurger + 1;
        return yesBurger;
    }

    function burgerDown () public returns (uint) {
        noBurger = noBurger + 1;
        return noBurger;
    }

    function readData() public view returns(uint, uint, uint, uint) {
        return (yesPizza, noPizza, yesBurger, noBurger);
    }
}