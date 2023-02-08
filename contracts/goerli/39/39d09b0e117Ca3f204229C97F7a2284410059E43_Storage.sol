/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Storage {

    uint256 public st_num;


    function store(uint256 num) public virtual {
        st_num = num;
    }


    function retrieve() public view returns (uint256) {
        return st_num;
    }


    function add_per_info(string memory add_name_per, uint256 add_per_num)
        public
    {

        person2.push(people(add_name_per, add_per_num));
        // For mapping
        name_to_num[add_name_per] = add_per_num;
    }

    // Arrays & Structs
    struct people {
        string name_per;
        uint256 per_num;
    }
    // Making a object of a struct
    people public person1 = people({name_per: "Lux", per_num: 71});
    // Making a fixed-size array
    // people[3] public person2;
    // Making a dynamic array
    people[] public person2;

    // Mapping
    mapping(string => uint256) public name_to_num;
}