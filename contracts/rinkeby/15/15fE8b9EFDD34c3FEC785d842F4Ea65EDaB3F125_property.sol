/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract property {
    string public name1 = "one";
    string public name2 = "two";
    string public cot = "three";

    function look1() public view returns(string memory) {
        return name1;
    }

    function look2() public view returns(string memory) {
        return name2;
    }
    
    function look3() public view returns(string memory) {
        return cot;
    }
    
    function add(string memory _name1, string memory _name2,string memory _cot) public {
        name1 = _name1;
        name2 = _name2;
        cot = _cot;
    }

}