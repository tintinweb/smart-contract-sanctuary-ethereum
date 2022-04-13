/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity >=0.4.16 <0.8.0;

contract CarSell{

address owner;
uint256 public carCount = 0;
mapping (uint=>Car) public Cars; //key - uint, value - Car


struct Car{
    bool beingUsed;
    uint8 doorsCount;
    string Mark;
    string Color;
    int Price;
}

modifier onlyOwner(){
    require(msg.sender == owner);
    _;
}

constructor () public {
    owner = msg.sender;
}

function incrementCount() internal{
    carCount += 1;

}

function addCar(bool beingUsed, uint8 doorsCount, string memory Mark, string memory Color, int Price) public onlyOwner{
    incrementCount();
    Cars[carCount] = Car(beingUsed, doorsCount, Mark, Color, Price);
}

}