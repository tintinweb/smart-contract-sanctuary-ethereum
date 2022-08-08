/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 fav;

    mapping(string => uint256) public nameToFav;

    struct People {
        uint256 fav;
        string name;
    }

    People[] public people;

    function store(uint256 _fav) public virtual {
        fav = _fav;
    }

    //view, pure
    function retrieve() public view returns (uint256) {
        return fav;
    }

    function addPerson(string memory _name, uint256 _fav) public {
        people.push(People(_fav, _name));
        nameToFav[_name] = _fav;
    }
}