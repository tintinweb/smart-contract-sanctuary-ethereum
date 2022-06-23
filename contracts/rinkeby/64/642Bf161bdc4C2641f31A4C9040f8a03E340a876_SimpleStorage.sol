/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //the first thing is to specify what version you are using because solidity is changing quickly

//^0.8.7 or >=0.8.7 <0.9.0

contract SimpleStorage {
    //primatives: bool: boolean, uint, int, address, bytes
    //bool hasFavoriteNum = flase;
    //uint256 (256bits is by default)
    //string favoriteText = "text";
    //bytes32 (32 is the maximum bytes)
    uint256 public favNumber; //initialized by default: 0
    //public, private, internal(default,private+children), external

    // People public person = People({favNumber: 2, name: "Kyle"});

    mapping(string => uint256) public nameToFavoriteNumber;
    // a dictonary, every possible key is been initialized to its null value:0

    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public people;

    // if you do not add a contrain of length, this array of people will have a dynamic length

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    //the syntax to make the function public here is quite strange

    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    //note that is "returns"
    //functions view, pure indicates that we disallow modification of information and this kind of function will not cost gas
    //pure additionally disallow reading from block chain state, maybe just do some algorithm

    function addPerson(string memory _name, uint256 _favNumber) public {
        //there will be two ways to create a new object:1.People(_favNumber, _name), the order of parameters matters; 2.People({name:"Patric", favNumber:2}),use the curly brackets.
        people.push(People(_favNumber, _name));
        nameToFavoriteNumber[_name] = _favNumber;
    }
    //calldata: temperarily, cannot be modified, memory: temporarily, storage:exist even outside the function call
}
//0xd9145CCE52D386f254917e481eB44e9943F39138