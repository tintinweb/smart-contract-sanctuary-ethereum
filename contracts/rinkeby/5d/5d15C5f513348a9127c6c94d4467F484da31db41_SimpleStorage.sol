// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    // this gets initialized to 0
    uint256 public favNo = 0;

    mapping(string => uint256) public nameToFavNo;

    struct People {
        uint256 favNo;
        string name;
    }

    People[] public people;

    function store(uint256 _favNo) public {
        favNo = _favNo;
    }

    function retrieve() public view returns (uint256) {
        return favNo;
    }

    function addPerson(string memory _name, uint256 _favNo) public {
        people.push(People(_favNo, _name));
        nameToFavNo[_name] = _favNo;
    }
}
//0xd9145CCE52D386f254917e481eB44e9943F39138