//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract SimpleStorage {
    //boolean, uint (unsigned integer positive whole number ),
    // int(positive or negative), address, bytes
    /* bool hasFavoriteNumber = true;
    uint256 favNum = 123; // uint8 to uint256 by default its uint256
    string favText = "five";
    int256 num= -5;
    address myAdd = 0x1EeE1410663Cb341ECf1df0ed6152b6849D9543F;
    bytes32 favBytes = "cat"; */

    uint256 favNum; //gets initialized to 0
    mapping(string => uint256) public nameToFavNum;
    struct People {
        uint256 favNumber;
        string name;
    }
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favNum = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(People(_favNumber, _name));
        nameToFavNum[_name] = _favNumber;
    }
}