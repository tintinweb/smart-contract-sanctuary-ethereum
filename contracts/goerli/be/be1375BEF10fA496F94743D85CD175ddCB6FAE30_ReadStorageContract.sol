/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

pragma solidity 0.8.13;

contract ReadStorageContract{
    
    // # 1 single variable uint
    uint256 firstVar = 100;

    // # 2 single variable string
    string secondVar = "Hello World";
    
    // #3 a constant
    string constant myConst = "I am a constant";
    
    // #4 two variables in one slot
    uint128 thirdVar = 5555;
    uint32 fourthVar   = 1000000;
    
    // #5 array
    uint32[20] numberArray = [10,15,20,30,40,50,60,70,100,200,300,400,500,600,700,800,900,1000,2000,3000];
    
    // #6 dynamic size array
    uint256[] dynamicArray;
    
    // #7 Struct
    PersonStruct myPerson;
    
    struct PersonStruct{
        string name;
        uint256 age;
    }
    
    // #8 mapping
    mapping(uint256 => uint256) myMapping;
    

    constructor(){
        myMapping[10] = 12345;
        myMapping[11] = 1234567890;
        
        myPerson.name = "Alice";
        myPerson.age  = 25;
        
        dynamicArray.push(1234);
        dynamicArray.push(5678);
    }   
}