// First to include in a solidity is version!
// ^ - Above the certain version, >=0.8.7 <0.9.0;
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.7;

contract SimpleStorage {
    // Boolean - True (or) False
    // uint - only positive whole numbers, we can also specify its size. This is by default initialised to zero!
    // int - +ve (or) -ve whole number, we can also specify its size.
    // Address - address.
    // Bytes - 0x123456- Max size of bytes is 32
    bool hasfavoriteNumber = true;
    uint256 favoriteNumber;
    string favoriteNumberInText = "Five";
    int256 favoriteInt = -45;
    address myAddress = 0x0CF90f65D56ad65dDC97AE5985C30aD80bB25Dc7;
    bytes32 favoriteBytes = "cat"; 
    
    // public (visibility) - We can see through the value it actually holds. visible externally and internally (creates a getter function for storage/state variables).
    // private - Only visible in the current contract.
    // external - only visible Externally(It is only for functions).
    // internal - only visible internally.
    function store(uint256 _favouriteNumber) public {
        favoriteNumber = _favouriteNumber;
        // retrieve(); //Now we need to pay the cost! 
    }

    // The more "Stuff", we do in a function, the more gas it costs.
    // When a function which has "view" and "pure" functions - we need not to spend gas as we are only reading it, It strictly disallow any modification (or) updation to the state.

    // If a gas calling function calls a view (or) pure function - only then will it cost gas!
    // "View" - It simply reads the state of the variable & no state will be changed. 
    // "Pure" - function declares that no state variable will be changed or read. we can simply return the value
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    // Struct - used to store range of dataTypes, same like that of uint (or) int.
    struct People {
        uint favoriteNumber; 
        string name;
    }

    // Arrays - It's a data structure that holds a list of other types.
    // uint256[] public favNum;
    People[] public people;

    // Mapping is a data structure where a "key" is mapped to a single value.
    mapping (string => uint256) public nameToFavouriteNumber; 
    
    // EVM can store data in diff ways:
    // 1) calldata - temp variable that can't be modified.
    // 2) memory - temp variable that can be modified and be applied only to string-arrays, struct and mapping not to uint or int!
    // 3) storage - permanent variable that can be modified.
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}