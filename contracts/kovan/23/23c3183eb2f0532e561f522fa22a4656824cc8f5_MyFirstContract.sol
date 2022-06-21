/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyFirstContract {

    string public my_name;
    uint256 public age;
    bool public sex;

    string public eat_storage;


    function eat(string memory eat_what) public {
        eat_storage = eat_what;
    }

    function setInfo(string memory _my_name, uint256 _age, bool _sex) public {
        my_name = _my_name;
        age = _age;
        sex = _sex;
    }

}