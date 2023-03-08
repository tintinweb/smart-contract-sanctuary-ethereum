//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; //defining the version of solidity

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    // bool hasFavouriteNumber = false;
    // string favNumberinText = "five";
    // int256 favouriteInt = -5;
    // address myAddress = 0x62161408042bbbeE52510bc427586B07c4dd803A;
    // bytes32 favouriteBytes = "cat";

    //This gets initialized to NULL value in solidity i.e. Zero
    uint256 favouriteNumber;
    // People public person = People({favouriteNumber: 2, name: "Subhradeep"});

    //mapping
    mapping(string => uint256) public nametoFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // uint256[] public listofObjects;
    People[] public personList;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    //view, pure keyword functions do not spend any gas, hence are shown in diff color.
    function retrive() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // People memory x = People({name: _name, favouriteNumber: _favouriteNumber});
        // personList.push(x);
        personList.push(People(_favouriteNumber, _name));
        //name mapped to its favourite Number
        nametoFavouriteNumber[_name] = _favouriteNumber;
    }
}