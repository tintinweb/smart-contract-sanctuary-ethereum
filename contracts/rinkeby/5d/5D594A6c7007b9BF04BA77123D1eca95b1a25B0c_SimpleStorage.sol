// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    //contract is sort of a class
    //Data Type: boolean, uint, int, address, bytes
    /*
    bool hasFavoriteNumber = false;
    uint256 favoriteNumber = 5;
    string favoriteNumberInText = "five";
    int256 favoriteInt = 5;
    address myAddress = 0xC5eA3f1ecA159C1343ebc65DB4C1E5998435541f;
    bytes32 favoriteBytes = "cat"; //bytes32 is the maximum size
    */

    uint256 favoriteNumber; //initialzed to 0
    // uint internal favoriteNumber; // this means it is private

    mapping(string => uint256) public nameToFavoriteNumber;
    //this is like a dict

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumbersList;
    //People[3] is a fixed size array
    People[] public people; //this is dynamic array

    //0: 2, Patrick | 1: 7, 'Jon'

    //virtual keyword allows the function to be overriden
    function store(uint256 _favoriteNumber) public virtual {
        //we spend gas when we change state of blockchain
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        //view and pure functions don't spend gas
        //view means reading a state
        //pure cannot read
        //but if you use view or pure function in a contract function, gas is spent
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        //pure function does not read anything
        return (1 + 1);
    }

    // calldata, memory, storage
    // calldata, memory only exists temporary
    // calldata is like a const (you cant change it)
    // memory is like a let (you can change it)
    // stoarage exists (permanent variables that can be modified - similar to static)
    // memory should be used for nonprimitive types (string is an array of char)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People(favoriteNumber: _favoriteNumber, name: _name); is also possible
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138