/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //any version above this

// pragma solidity >=0.8.7 < 0.9    --> version above 0.8.7 but strictly less than 0.9

contract SimpleStorage {
    // bool, uint, int, address, bytes, string
    uint256 favouriteNumber; //unit(here we write bits if not mentioned then default is 256bits)
    address myaddress = 0x6F6b61Bc2668415c42926Dab2781211c10EC1030;
    string mystring = "hello world";
    bytes32 myfavBytes = "cat"; //this will convert cat to something like 0x3424h23432blkk...

    //max no. that can be allocated with bytes is 32 and with uint or int is 256(cause this is in bits)

    // if a function is a view or pure type then no gas is used unless this function is called
    // inside some gas consuming function
    function store(uint256 _favouriteNumber) public virtual {
        // will consume gas
        favouriteNumber = _favouriteNumber;
    }

    // view/pure
    function retrieve() public view returns (uint256) {
        //will not consume gas unless called inside a gas consuming func
        return favouriteNumber;
    }

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // People person = People({favouriteNumber:10, name: "mohit"});
    People[] public listPeople;

    // mapping
    mapping(string => uint256) public nameToFav;

    // memory --> temp variables that can be modified
    // calldata --> temp. variables that can't be modified
    // storage --> permanent var that can be modified
    function addPeople(uint256 _favNo, string memory _name) public {
        //if u take string as parameter has to define location to variable like memory, call data, etc
        nameToFav[_name] = _favNo; // mapping
        People memory person = People({favouriteNumber: _favNo, name: _name}); //in case of struct dont have to use new keyword, instead have to define location type
        // listPeople.push(People(_favNo, _name));
        listPeople.push(person);
    }

    // function lol() public {
    //     uint256 hello = 2;
    // }
}