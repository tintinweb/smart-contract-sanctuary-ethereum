/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // stable version

contract SimpleStorage {
    // this gets initialized to zero!
    uint256 favoriteNumber;
    // Ex using variable creation: People public person = People({favoriteNumber: 2, name: "Charley"});

    // mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    // Creating a struct of people. People object.
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumbersList;
    People[] public people;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // 1st way
        people.push(People(_favoriteNumber, _name));
        //2nd way
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);
        //3rd way
        //People memory newPerson = People(_favoriteNumber, _name);
        //people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view & pure functions don't cost gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure function
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    //calldata, memory, storage
    //calldata-only temporarily variables, that can't be modified
    //storage- permanent variables that can be modified. exist outside function executing
    //memory - temp variable that can be modified
    //need to use memory for array, structs, or mapping types
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138 - first deployed contract address