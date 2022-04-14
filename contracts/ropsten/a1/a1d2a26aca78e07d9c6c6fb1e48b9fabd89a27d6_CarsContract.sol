/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >=0.7.0 <0.9.0;
contract CarsContract
{
address owner;
uint public CarsCount = 0;
struct Car{
bool isNew;
uint doorsAmount;
string brand;
string color;
uint mileage;
int price;
}
Car[] public CarBug;
modifier onlyOwner(){
require(msg.sender==owner);
_;
}

constructor() public {
owner = msg.sender;
}
function incrementCount() internal{
CarsCount++;
}
function addCar(bool isNew, uint doorsAmount, string memory brand, string memory color, uint mileage, int price) public onlyOwner{
incrementCount();
CarBug[CarsCount]=Car(isNew,doorsAmount,brand,color,mileage,price);
}
function showCar() public view
returns (bool isNew, uint doorsAmount, string memory brand, string memory color, uint mileage, int price)
{
return (CarBug[CarsCount].isNew,CarBug[CarsCount].doorsAmount,CarBug[CarsCount].brand,CarBug[CarsCount].color,CarBug[CarsCount].mileage,CarBug[CarsCount].price);
}
}