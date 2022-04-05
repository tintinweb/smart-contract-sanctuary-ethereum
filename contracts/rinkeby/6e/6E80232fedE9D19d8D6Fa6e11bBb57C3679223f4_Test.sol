/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Test {

    string public name;

    constructor(string memory _name){
        name = _name;
    }
    function getName() public  view returns (string memory ){
        return name;
    }
    function setName(string memory _name) public {
        name = _name;
    }

}