// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public persons;

    function store(uint256 _favoriteNumber) public virtual {
        // virtual for override
        favoriteNumber = _favoriteNumber;
        // retrieve(); // view or pure functions when called by a gas calling function will cost gas
    }

    //transaction cost
    // 43746 -- without view
    // 43886 -- with retrieve

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        persons.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}