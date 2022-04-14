/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >=0.4.16 <0.8.0;

contract MyCars {
    
        uint256 public CarsCount = 0;
        Car[] public Cars;

struct Car {
        bool state;
        uint8 doors;
        string mark;
        string color;
        uint mileage;
        int price;
}

function add(bool state, uint8 doors, string memory mark, string memory color, uint mileage, int  price ) public {   
        CarsCount +=1;
        Cars.push(Car(state, doors, mark, color, mileage, price));
}


function show() public view returns (uint256){
        return CarsCount;
    }
}