/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract tryment{
    /*
    dulala dulala duladulala
    lalalalala
    ababababa
    */
    int public age;
    address private owner;
    string  public name="this";

    constructor(int _age,string memory _name){
        age=_age;
        name=_name;
        owner=msg.sender;
    }

    function change_age(int _age) public{
        age=_age;
    }
}