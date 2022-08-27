/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Storage {
    uint256 myNumber = 0;

    function retrieve() public view returns (uint256) {
        return myNumber;
    }

    function updateMyNumber(uint256 _myNumber) public {
        myNumber = _myNumber;
    }

    struct Friends {
        string name;
        uint256 age;
        string occupation;
    }

    Friends[] public friends;
    mapping(string => Friends) public myFriends;

    function addFriends(
        string memory _name,
        uint256 _age,
        string memory _occupation
    ) public {
        friends.push(Friends(_name, _age, _occupation));
        myFriends[_name] = Friends(_name, _age, _occupation);
    }
}