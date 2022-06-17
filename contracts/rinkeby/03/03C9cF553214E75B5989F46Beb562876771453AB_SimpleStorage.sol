// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;
    // gets inititialized zero, following examples

    // bool hasFavoriteNumber = true;

    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = 0x25549a401f9C04c51d13202f6C87A2c244325A5C;
    // bytes32 favoriteBytes = "cat";

    // second I definded the variable
    // People public person = People({
    //     favoriteNumber: 22,
    //     name: "foo"
    // });

    // I created the struct first
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    // then I added the array and pushed Peoples in it
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and return functions don't modify the blockchain
    // and therefore cost no gas, unless in a gas-costing function used
    // pure doesn't even read from the bc
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata (local + immutable),
    // memory (local + mutable),
    // storage (global)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

//compiled in yarn with the following command:
// yarn solcjs --bin --abi --include-path node_modules/ --base-path . -o . SimpleStorage.sol
// roughly translated to:
// yarn run solc and create binaries and ABI, include all the modules, where is the basepath and output and the file to compile