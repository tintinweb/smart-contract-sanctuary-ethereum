/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract SimpleStorage {
    uint256 favoriteNumber;
    // Person public person = Person({favoriteNumber: 2, name: "Ray"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    // declare dynamic sized person struct array
    // uint256[] public favoriteNumbersList;
    Person[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view & pure functions when called alone dont spend gas, diallow any modifications to the state
    // view function only reads from the state
    // pure function only computations no read or updating state

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // memory - exist temporarily whilst the function/transaction is running,
    // calldata - special data location that contains function arguments :- TEMPORARY VARAIABLE THAT CANNOT BE MODIFIED
    // storage - variable is stored on the blockchain i.e (state variable)

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // Person memory newPerson = Person({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);
        people.push(Person(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// EVM can access and store information in six places
// 1. Stack
// 2. Memory
// 3. Storage
// 4. Calldata
// 5. Code
// 6. Logs