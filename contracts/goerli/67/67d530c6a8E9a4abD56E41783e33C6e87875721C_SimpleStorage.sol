// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber + 1;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

// contract SimpleStorage {
//     // variables
//     uint256 FavNumber;

//     // Functions
//     function store(uint256 _FavNumber) public {
//         FavNumber = _FavNumber;
//         uint256 tstVar = 5;
//     }

//     function RetrieveBrrr() public view returns (uint256, uint256) {
//         return (_FavNumber, tstVar);
//     }
// }