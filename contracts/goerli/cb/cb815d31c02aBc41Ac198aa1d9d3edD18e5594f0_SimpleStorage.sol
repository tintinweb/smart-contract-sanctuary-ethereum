//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    struct people {
        string name;
        uint256 fav;
    }
    people[] public pplArr;
    uint256 public current;
    mapping(string => uint256) public nametofav;

    function store(string memory _name, uint256 _fav) public virtual {
        current = _fav;
        nametofav[_name] = _fav;
        pplArr.push(people(_name, _fav));
    }

    function retrieve() public view returns (uint256) {
        return current;
    }
}