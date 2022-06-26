// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//  you can also write your ppragm like: 
// pragma solidity ^0.8.7  any version above 0.8.7
// pragma solidity >=0.8.7 < 0.9.0; all version from 0.8.7 to 0.8.9

contract SimpleStorage{
    // Data types
    // BOOLEAN :true/ false value
    // UINT: unsigned integer can be posive integer
    // INT: Signed integer can be positive or negative whole number
    // ADDRES:
    // BYTES

    //  Varibles are holder for different value 

    // bool hasFavNumber = false;
    // uint256 favNumber = 123;
    // int256 favNumber1 = -5;
    // string favNumberInText ="Five";
    // address myAddress =  0x24a83Bb9e421D16075F9bB5508b32Ddcd9949111;
    // bytes32 favBytes = "cat" 

    // Intitalized to zero
    uint256 favNumber;
    People public person = People ({favNumber: 2, name:"Matthew"});  

    // mapping (dictionary)
    mapping(string => uint256) public nameToFavNumber;

    // Struct (object)
    struct People {
        uint256 favNumber;
        string name;
    }

    // Array
    // Dynamic array because the size is not fixed
    People[] public people;

    // Default visibility of this variable is internal
    // uint256 public favNumber;

    // function
    //  View and pure function don't spend gas
    //  View and pure function disallow any modification of state
    //  Pure functions additionally disallow you to read from blockchain state
    //  Note: of a gas calling function calls a view or pure function- only then will it costs gas
    function store(uint256 _favNumber) public virtual{
        favNumber = _favNumber;
        // favNumber++;
        retrive();
    }

    function add() public pure returns(uint256) {
        return(1 + 1);
    }

    function retrive() public view returns(uint256){
        return favNumber;
    }

    // Memory(can be modified and are specified for array, struct and mapping) and calldata(can't be modified): means that a variable will exist temporary  during which its called
    // Storage means variable exist outside where d varible is declared
    function addPerson(string memory _name, uint256 _favNumber) public{
        // People memory newPerson = People(_favNumber, _name);
        // people.push(newPerson);
        // or
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }

}