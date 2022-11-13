// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //>=0.8.7 <0.9.0 //0.8.12 ^0.8.7

contract SimpleStorage {
    // types : boolean, uint, int, address, bytes
    // bool hasFavouriteNumber = true;
    // uint256 favouriteNumber = 123;
    // string NumberInText = "Two";
    // int256 favouriteInt = -3;
    // address myAddress = 0x59EbD738A323866cFffa9ce63Df4a311A60e1a93;
    // bytes32 favouriteByte="cat"; // 0x234j2n34j324n
    uint256 public favouriteNumber; // initialized to 0 and visibility is internal by default

    // Person public person = Person({favouriteNumber: 34, name: "Deekshith"});

    Person[] public people;

    struct Person {
        uint256 favouriteNumber;
        string name;
    }

    mapping(string => uint256) public nametoFavouriteNumber;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
        //retrieve(); //costs gas
        // favouriteNumber += 1;
        //uint256 temp1 = 4;
    }

    // function random() public{
    //     uint t=temp1; //can't access
    // }

    //view, pure
    function retrieve() public view returns (uint256) {
        //calling it only does not cause gas, as it just reads from contract
        return favouriteNumber;
    }

    //calldata & memory -> exists temporarily, storage is give by default
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // Person memory newPerson = Person({
        //     favouriteNumber: _favouriteNumber,
        //     name: _name
        // });
        Person memory newPerson = Person(_favouriteNumber, _name);
        people.push(newPerson);
        nametoFavouriteNumber[_name] = _favouriteNumber;
        // people.push(Person(_favouriteNumber,_name));
    }

    // 0xd9145CCE52D386f254917e481eB44e9943F39138
}