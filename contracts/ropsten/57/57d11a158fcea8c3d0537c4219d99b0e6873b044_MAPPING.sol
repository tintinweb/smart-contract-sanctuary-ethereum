/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
contract MAPPING{
    mapping(address=>uint)internal values;
    
    address[] public keylist;
    function addvalue(address  _key, uint _val)public{
        values[_key]=_val;
            keylist.push(_key);
         }   
function GetVALEbyindex(uint i)public view returns(uint){
    return values[keylist[i]];
    }
   
    function sizeofmap()public view returns(uint){
        return uint(keylist.length);
    }
    function getBykey( address _key)public view returns(uint){
        return values[_key];
    }}