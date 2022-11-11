// SPDX-License-Identifier: MIT
pragma solidity 0.8.12; //comment compiler version

contract SimpleStorage {
    // This gets initialized to zero
    uint256 favoriteNumber;
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // retrieve();
    }

    // keywords that does not require gas to run the keywords are view and pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // callData -> we cannot change the value of the variable and it is temporary storage (means storage exists for function only)
    // memory -> we can change the value of the variable and and it is also temporaray storage.
    // storage -> it is permanenet memory and when global variable is declared like(favoriteNumber) it's default storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People(_favoriteNumber,_name);
        // people.push(newPerson);
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
// 0xd9145CCE52D386f254917e481eB44e9943F39138