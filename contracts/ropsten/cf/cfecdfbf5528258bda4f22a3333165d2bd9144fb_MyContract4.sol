/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

pragma solidity >=0.4.16 <0.8.0; 

contract MyContract4 {

    uint256 public carCount = 0;
    address owner;

    mapping (uint=>Car) public cars;

    struct Car {
        bool is_new;
        uint8 doors;
        string name;
        string color;
        uint mileage;
        int price;        
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function incrementCount() internal{
        carCount += 1;
    }

    function addCar(
        bool is_new,
        uint8 doors, 
        string memory name, 
        string memory color, 
        uint mileage, 
        int price) public onlyOwner{
            incrementCount();
            cars[carCount] = Car(is_new, doors, name, color, mileage, price);
    }
}