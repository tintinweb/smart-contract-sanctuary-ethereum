/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >= 0.4.16 <0.8.0;

contract MyContract {    
    Car[] public car;           
    uint64 public carCount;    

    struct Car {
        string colour;
        string marka;                
        bool used;
        uint8 doors;
        uint32 probeg;
        uint32 price; 
    } 

    function add(string memory colour, string memory marka, bool used, uint8 doors, uint32 probeg, uint32 price) public {   
        carCount+=1; 
        car.push(Car(colour, marka, used, doors, probeg, price)); 

    }

    function machine() public view returns(uint64) {   
        return carCount;
    }
}