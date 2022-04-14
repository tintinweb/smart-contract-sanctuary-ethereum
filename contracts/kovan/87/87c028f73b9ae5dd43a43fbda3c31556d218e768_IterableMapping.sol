/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IterableMapping{
    mapping(uint=>uint) public data;
    uint[] public keys;
    mapping(uint=>bool) public exists;
    mapping(uint=>uint) public indexOf;
    function add(uint _key,uint _data) public {
        data[_key]=_data;
        if(!exists[_key]){
            exists[_key]=true;
            indexOf[_key]=keys.length;
            keys.push(_key);
        }
    }


    function get(uint id) public view returns(uint){
        require(id<keys.length,"Please Enter valid Id");
        return data[keys[id]];
    }


    function remove(uint key) public returns(bool) {
        if (!exists[key]) {
            return false;
        }

        delete exists[key];
        delete data[key];

        uint index = indexOf[key];
        uint lastIndex = keys.length - 1;
        uint lastKey = keys[lastIndex];
         indexOf[lastKey] = index;
         delete indexOf[key];
         keys[index] = lastKey;
         keys.pop();
         return true;
    }

    
}