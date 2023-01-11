/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8; 


contract Simple_Storage {
    int256 public favorite_number;


    function store(int256 _favorite) public virtual {
        favorite_number = _favorite;
    }


    function ret_favorite_number() public view returns (int256) {
        return favorite_number;
    }


    struct People {
        string name;
        int256 favorite_number;
    }

    function ret_newperson(
        string calldata _name,
        int256 _favorite_number
    ) public pure returns (People memory) {
        People memory newperson = People(_name, _favorite_number);
        return newperson;
    }

    mapping(string => int256) public People_mapping; 

    function add_person(string calldata _name, int256 _favorite_number) public {
        People_mapping[_name] = _favorite_number; 
    }
}