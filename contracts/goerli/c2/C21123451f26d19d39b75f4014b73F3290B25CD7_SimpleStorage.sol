// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    /*
    bool hasFavoriteNumber = true;
    uint favoriteNumber = 5;
    string favoriteNumberInText = "Five";
    int256 favoriteInt = -5;
    address myAddress = 0x66785787BB8e17e0B3E4fDF64D59715f3cF54e84;
    bytes32 favoriteBytes = "cat";
    */
    uint256 favoriteNumber;
    //People public person = People({favoriteNumber: 2, name: "Jane"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //retrieve(); <- this will cost gas
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //view,pure <- does not spend gas,
    // <- unless calling it from a function that costs gas (see above)
    //only reads from blockchain (blue icon in deploy)
    //only when modifying things on blockchain will cost (orange icon in deploy)

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //people.push(People(_favoriteNumber, _name));
        //same as below
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
    //calldata => temporary variable that can't be modified
    //memory => temporary variable that can be modified
    //storage => permanent variable that can be modified
}