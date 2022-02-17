/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

pragma solidity >=0.7.0 <0.9.0;

contract flipper{
    bool private value;

    constructor(bool initvalue){
        value = initvalue;
    }

    function flip() public {
        value = !value;
    }

    function get() public view returns (bool){
        return value;
    }
}