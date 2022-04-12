/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

//07.04.22
pragma solidity <=0.8.0;

contract MyContract5 {

modifier onlyOwner(){
    require(msg.sender==owner);
    _;
}

function incrementCount() internal {
    carCount++;
}

constructor() public {
    owner = msg.sender;
}

address owner;
uint256 public carCount = 0;

mapping (uint=>Car) public cars;

    struct Car {
        bool notUsed;
        uint8 doors;
        string mark;
        string color;
        uint mileage;
        int price;
        
    }
  
    function addCar(bool  notUsed, uint8  doors, string memory mark, string memory color, uint  mileage, int  price ) public onlyOwner {

        
        if(doors>4) doors = 4;
        incrementCount();
        cars[carCount] = Car(notUsed, doors, mark,color,mileage,price);

    }

   

}