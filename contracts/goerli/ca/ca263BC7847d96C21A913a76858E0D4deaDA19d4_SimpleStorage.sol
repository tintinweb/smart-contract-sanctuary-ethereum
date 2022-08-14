/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

pragma solidity ^0.6.0;

contract SimpleStorage {
    uint private value;

    function getValue() public view returns(uint) {
        return value;
    }

    function setValue(uint newValue) public {
        value = newValue;
    }
}