/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract A{
    uint public a ;

    function contract_address() public view returns( address ) {
        return address( this ) ;
    }

    function setA(uint _a) public {
        a = _a ;
    }

    function mul(uint _a, uint _b, uint _c) public pure returns(uint) {
        return _a * _b * _c ;
    }   

}