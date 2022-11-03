//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7; // version but not the latest(0.8.12)

//compiled in the Ethereum Virtual Machine (EVM)
// Avalanche, Fanton, Polygon

contract SimpleStorage {
    //Declaration
    //boolean, uint, int, adddress, bytes
    uint256 public favouriteNumber;

    // mapping
    mapping(string => uint256) public nameToFavouriteNumber;
    //New type
    //Structs in Solidity allows you to create more complicated data types that have multiple properties. You can define your own type by creating a struct. They are useful for grouping together related data. Structs can be declared outside of a contract and imported in another contract.
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    //Array
    // dynamic array
    //uint256[] public favouriteNumbersList;
    People[] public people;

    // Functions
    function store(uint256 _favouriteNumber) public virtual {
        //overriding must add virtual
        favouriteNumber = _favouriteNumber;
        // favouriteNumber = favouriteNumber + 1; // cost of gas
    }

    function retrieve() public view returns (uint256) {
        // view, pure doesn't use gas when executed
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People({
            favouriteNumber: _favouriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}