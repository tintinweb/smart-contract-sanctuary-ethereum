// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.8; anyu version of 0.8.7 and above is okay for this contract
// pragma solidity >=0.8.7 <0.9.0; to choose between two contract version ranges

pragma solidity ^0.8.8; // version specification

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = false;
    // string favoriteNumberInText = "Seven";
    // int256 favoriteInt = -7;
    // address myAddress = 0xCF529119C86eFF8d139Ce8CFfaF5941DA94bae5b;
    // bytes32 favoriteBytes = "cat"; // 0x12329378qeigqp39oiughq
    // People public person = People({favoriteNumber: 7, name: "Andrew Tate"});
    // uint256[] public favoriteNumbersList;

    uint256 favoriteNum; // this gets automatically initialized to zero!..
    People[] public people;

    // mapping a key to a single value:
    mapping(string => uint256) public nameToFavoriteNumber; // it is equivalent to javascript objects where {key: value} are stored

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Functions || (methods)

    function store(uint256 _favoriteNumber) public virtual {
        // virtual keyword allows the function to be overrideable†
        favoriteNum = _favoriteNumber;
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNum;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // People memory newPerson = People(_favoriteNumber, _name);
        // people.push(newPerson);
        people.push(People(_favoriteNumber, _name)); // can be passed in as parameters to the People type
        nameToFavoriteNumber[_name] = _favoriteNumber; // setting a key(_name) equal to a value(_favoriteNumber) (mapping)
    }

    // function add() public pure returns(uint256) {
    //     return(1+1);
    // }
}

// 0xD7ACd2a9FD159E69Bb102A1ca21C9a3e3A5F771B => address of the current contract deployed to the current virtual machine