// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}




// pragma solidity ^0.8.8;

// import "hardhat/console.sol";

// // Uncomment this line to use console.log
// // import "hardhat/console.sol";

// contract SimpleStorage {
//     string private greeting;

//     constructor() {
//         console.log("Deploying a Greeter with greeting: Mamitiana");
//     }

//     // function print() public {
//     //     console.log("This is a test");
//     // }
// }