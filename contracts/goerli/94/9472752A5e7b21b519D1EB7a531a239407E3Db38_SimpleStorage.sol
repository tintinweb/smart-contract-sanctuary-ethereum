// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* 
 Solidity is an object oriented, high level language for implementing smart contracts
 Smart contracts are programs which govern the behaviour of accounts within the Ethereum state.
 A blockchain is a globally shared, transactional database
*/

contract SimpleStorage{
    // boolean, int, uint, string, address, bytes, struct, array, mapping
    // you can specify the memory storage for int and uint in multiples of 8 eg uint8, int16 ... int256
    // you can specify the memory storage for bytes in addtions of 1 eg bytes2 ...bytes32
    
    // this gets initialized to 0, adding public automatically makes the varibale accessible from outside
    uint256 public favouriteNumber; 

    // you can create custom datatype using the struct keyword, you can use it as an object or array
    struct People{
        uint256 favouriteNumber;
        string firstName;
    }
    //obj example
    People public person = People({favouriteNumber:2, firstName:'Emeka'});

    // to create an array put [] after the datatype
    // to define the size of the array put a number in the box eg [5], this means the array will
    // have 5 elements, if you don't define that it will be a dynamic array, it will grow with the elements added       
    People[] public persons;
    // mapping datatype is like a dictionary
    mapping(string => uint256) public nameToFavouriteNumber;

    function addPerson(uint256 _favouriteNumber, string memory _firstName) public{
        nameToFavouriteNumber[_firstName] = _favouriteNumber;
        persons.push(People({favouriteNumber:_favouriteNumber, firstName:_firstName}));       
    }
    /*
        * data location must be memory or calldata for paramters in functions. 
        * calldata cannot be modified while memory can be modified. 
        * calldata and memory data will only exist temporarily unlike storage which exist permanetly and can be modified,
        * global variables are stored in the storage.
        * In solidity we can store data in 1.Stack 2.memory 3.storage 4.calldata 5.code 6.logs
        * For function parameters, data location is only specified for array, string(an array of bits), struct, mapping types you dont
           need to specify that for uint, int parameters
    */
   
  
   // add virtual keyword if you want a child contract to be able to override this function
    function store(uint256 _favouriteNumber) public virtual{
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favouriteNumber;
    }
}