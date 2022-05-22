/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity 0.8.10;
// SPDX-License-Identifier: MIT

contract name{
    string public name ;
    address public add ;
    uint public total ;
    constructor(string memory _name){
        name = _name;
        add = msg.sender;
    }
    modifier check{
        require(add == msg.sender,"not creator address");
        _;
    }
    function get_Name()public view returns(string memory){
        return name ;
    }
    function set_Name(string memory _name)public{
        require(add == msg.sender,"not creator address");
        // require(_name != "","fill name");
        name = _name ;
    }
    function get_Total()public view returns(uint){
        return total;
    }
    function add_Total(uint _x)public check{
        require(_x > 0 ,"x must be than zero");
        total += _x;
    }
}