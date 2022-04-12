/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity <=0.8.0;


contract MyContract5 {

    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }


    function incrementCount() internal {
        carCount++;
    }

    address owner;
    uint private carCount = 0;

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

      constructor() public {
        owner = msg.sender;
        addCar(true,4,"bmw","black",500,10000);
        addCar(true,4,"audi","red",9,100000);
    }

    function showAllCars() public view returns ( uint[] memory, Car[] memory ){
        
        uint len = carCount;
        uint[] memory keys = new uint[](len);
        Car[] memory values= new Car[](len);
        for (uint i = 0 ; i <  carCount ; i++) {
            keys[i] = i+1;
            values[i] = cars[i+1];
         }
        return (keys,values);
           
        
    }

       function showByNumber(uint number) public view returns (bool notUsed ,uint8 doors,string memory mark,string memory color,uint mileage,int price){
        if(number>carCount||number<=0) return (false,0,"","",0,0);
        return (cars[number].notUsed, cars[number].doors, cars[number].mark, cars[number].color, cars[number].mileage, cars[number].price);

    }


}