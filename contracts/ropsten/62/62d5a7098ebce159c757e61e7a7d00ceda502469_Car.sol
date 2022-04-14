/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >=0.4.16 <0.8.0;

contract Car{   
    Car[] public cars; 
    uint public numberCars = 0;     
    struct Car{
        uint id_; 
        bool isOld_; 
        uint8 countDoor; 
        string brand; 
        string color;
        uint mileage; 
        int price; 
    }

    function addCar(bool isOld_, uint8 countDoor, string memory brand, string memory color, uint mileage, int price) public{   
        numberCars+=1; 
        Car memory car_ = Car(numberCars, isOld_,countDoor, brand, color,mileage,price);
        cars.push(car_); 
    }


    function getCars(uint id_) public view returns(uint, bool, uint8,string memory, string memory,int){
        Car memory car_ = cars[id_]; 
        return (car_.id_, car_.isOld_, car_.countDoor, car_.brand,car_.color,car_.price); 
    }
}