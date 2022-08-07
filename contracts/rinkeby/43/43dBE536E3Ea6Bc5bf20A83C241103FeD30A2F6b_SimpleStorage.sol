// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // Declare version of solidity  ^ = Upwards compatibility >= ranged compatibility

// EVM, Ethereum Virtual Machine
//Avalanche, Fantom, Polygon

//Declare contract
contract SimpleStorage {
    //Types: boolean,uint,int,address,bytes
    uint256 favouriteNum;

    //Array
    People[] public people;

    //Mapping
    mapping(string => uint256) public nameToFavNum;

    function store(uint256 _favNum) public virtual {
        favouriteNum = _favNum;
    }

    //View/Pure fucntion, does not update state on blockchain or Read
    function retrieve() public view returns (uint256) {
        return favouriteNum;
    }

    // No gas spent for pure/View as a no transaction happens.
    //Off-chain. Unless you call inside of function that costs.
    function add() public pure returns (uint256) {}

    // Struct
    //People public person = People({favouriteNum:2,name:"chike"});
    struct People {
        uint256 favouriteNum;
        string name;
    }

    //Structs, mapping and arrays need to be given memory or calldata key word when adding to function param
    //calldata, memory, storage
    function addPerson(string memory _name, uint256 _favNum) public {
        //people.push(People(_favNum,_name));
        People memory newPerson = People({favouriteNum: _favNum, name: _name});
        people.push(newPerson);

        nameToFavNum[_name] = _favNum;
    }
}