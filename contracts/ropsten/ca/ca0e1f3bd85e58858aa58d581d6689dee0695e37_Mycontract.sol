/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >=0.4.16 <0.8.0;

contract Mycontract{
    Cars[] public car;
    uint32 public carCount;

    struct Cars{
        string colour;
        string marka;
        bool used;
        uint8 doors;
        uint32 mileage;
        uint32 price;
    }
    function add(string memory colour, string memory marka, bool used, uint8 doors, uint32 mileage, uint32 price) public {
        carCount +=1;
        car.push(Cars(colour, marka, used, doors, mileage, price));

    }
    function show() public returns(uint32) {
        return carCount;
    }


}