// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

//EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {

    // This gets initialized to zero!
    // <- This means that this section is a comment!
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumbr;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }
    // view, pure
    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    // calldata, memory, storage

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumbr[_name] = _favoriteNumber;
    }

    

}
// 0xd9145CCE52D386f254917e481eB44e9943F39138