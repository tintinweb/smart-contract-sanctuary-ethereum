/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

pragma solidity >=0.4.16 <0.8.0;

contract myContract3{
    struct Car{
        bool age;
        uint door;
        string brand;
        string color;
        uint probeg;
        int price;
    }



Car[] public Carz;
uint8 public CarzCount; 

    function add(bool age, uint door, string memory brand, string memory color, uint probeg, int  price ) public {   
    CarzCount +=1;
    Carz.push(Car(age, door, brand, color, probeg, price));
}


    function show() public view returns (uint8){
        return CarzCount;
    }
}