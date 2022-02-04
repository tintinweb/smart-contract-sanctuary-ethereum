/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

struct Student {
    string name;
    string class;
}

contract struct_mapping {

mapping(uint256 =>Student) public MapIdToName;

    function setter(uint256 _id , string memory _name , string memory _class) public {
        MapIdToName[_id] = Student({
            name: _name,
            class: _class 
        }); 
    }

    function get_name(uint256 _id) public view returns(string memory){
       return MapIdToName[_id].name;
    }

    function get_class(uint256 _id) public view returns(string memory){
       return MapIdToName[_id].class;
    }

}