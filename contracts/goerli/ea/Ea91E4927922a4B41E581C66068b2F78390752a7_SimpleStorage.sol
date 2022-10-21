/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 < 0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber;
    //uint256 is the same as uint
    //A contract is just like a class in OOP language, like c#
    //People[] public person = People({favoriteNumber: 2, name: "Sam Ade"});
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people; // This is an empty array of type People

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //favoriteNumber = favoriteNumber + 1; including this will increase gas cost
    }

    //view function is only reading what the favoriteNumber is
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //memory is not indicated before _favoritrNumber because Data location can only be specified for array, struct or mapping types, but "memory" was given
        //string is an array of byte
        //people.push(People(_favoriteNumber, _name)); This is another way to add. However, for this, no need for memory(but there will be memory in the function's variable)
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138