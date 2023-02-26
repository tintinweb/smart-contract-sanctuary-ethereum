//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    //uint default is 256
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber; //resolve type to type

    struct People {
        //creates new type
        uint256 favoriteNumber;
        string name;
    }
    //uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        //view + pure don't modify blockchain
        return favoriteNumber;
    }

    //calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //memory keyword means variable only exists during duration of function
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
//0xd9145CCE52D386f254917e481eB44e9943F39138 SC Address