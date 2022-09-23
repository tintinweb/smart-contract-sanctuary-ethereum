/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.0;

contract AAA {
    string[] names;

    function addName (string memory _name) public {
        names.push(_name);
    }

    function read (uint _n) public view returns(uint, string memory) {
        return (names.length, names[_n - 1]);
    }
}