/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7 <0.9.0;

contract Test {
    struct People {
        string name;
        uint age;
    }

    uint public favNumber = 10;

    People[] public addPerson;
    mapping(uint => string) public findName;

    function add(string memory _name, uint _age) public {
        addPerson.push(People(_name, _age));
        findName[_age] = _name;
    }

    function addFav(uint _fav) public virtual {
        favNumber = _fav;
    }

    function rtn() public view returns (uint256) {
        return favNumber;
    }
}