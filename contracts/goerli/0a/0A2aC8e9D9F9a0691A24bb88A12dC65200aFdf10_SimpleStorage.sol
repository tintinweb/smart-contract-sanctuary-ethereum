// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // This gets initialized to 0
    // This variable automatically stored in "storage" memory
    uint256 public favoriteNumber;

    // Every single name will map with specific number
    mapping(string => uint256) public nameToFavoriteNumber;

    // This is our structure
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //people is our array
    People[] public people;

    //Example of the basic function
    //Add here keyword virtual to override function in another conrtact
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view function doesn't do any changes in the blockchain
    // it only reads => so it doesn't spend any gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // mappins, structs, arrays should be stored in "memory" (take a look below what is memory)
    function AddPerson(string memory _name, uint256 _favoriteNumber) public {
        // пушим в массив people новый объект
        // memory keyword says that the "name" parameter will be exists temporarily during the transaction
        people.push(People(_favoriteNumber, _name));
        // we map for each name the specific number
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}