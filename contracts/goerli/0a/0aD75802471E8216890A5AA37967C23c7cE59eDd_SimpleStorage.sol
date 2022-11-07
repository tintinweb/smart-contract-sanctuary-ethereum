// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    //Stores number to favoriteNumber
    // Need to add virtual so it can be overriden in a child contract
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //Shows favoriteNumber
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // Adds person to People[]
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// Contract Hasbu, Rozik; 0x42487CAb88855D2581B868b389Ce6991e695FDA3
// Hasbu: 0xc104b134243c70b4dc95d9eddc2381513ffeb88e8424abdadef37b0fce4bfc2e
// Rozik: 0x974bc9cd343207bac6c5a6e227218b240e23f9b63633f889f2010628b31d9db2