//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public value;

    function setdata(uint x) public virtual {
        value = x;
    }

    function retrieve() public view returns (uint) {
        return value;
    }

    struct People {
        uint favNum;
        string name;
    }
    mapping(string => uint256) public nameToFavNum;
    People public person = People({favNum: 5, name: "Ujjawal"});
    People[] public PeopleArray;

    function setArray(string memory s1, uint fav) public {
        PeopleArray.push(People(fav, s1));
        nameToFavNum[s1] = fav;
    }

    function viewdata() public view returns (uint) {
        return value;
    }
}