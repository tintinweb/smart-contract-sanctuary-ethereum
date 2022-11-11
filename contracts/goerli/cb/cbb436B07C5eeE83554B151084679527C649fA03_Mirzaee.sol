// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Mirzaee{
    uint  number;
    constructor (uint _number){
        number=_number;
    }
    function set(uint _a)public {
        number=_a;
    }
    function get()public view returns(uint){
        return number;
    }
}