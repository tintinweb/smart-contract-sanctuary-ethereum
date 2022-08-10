// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // boolean, uint, int, address, bytes, string
    /*
    bool hasFavoriteNumber = true;
    uint256 favoriteNumber = 5;
    string favoriteNumberInText = "Five";
    address myAddress = 0xA8C457930129a4825227c12706Ad99b7E4528Ac0;
    bytes3 favoriteBytes = "cat";
    */
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    People public person = People({favoriteNumber: 2, name: "Patrick"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure function (no gas)
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure cannot read blockchain state
    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        // people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
// 0xd9145CCE52D386f254917e481eB44e9943F39138