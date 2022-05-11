/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract A {
    uint256 age;
    string name;
    uint256 value;
    uint256 pass = 7777777;

    function setName(string memory _name) public payable{
        name = _name;
        value = msg.value;
    }

    function getName() public view returns(string memory){
        return name;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getLatestValue() public view returns(uint256){
        return value;
    }

    function withdraw(uint256 _amount, uint256 _pass) public {
        require(pass == _pass,"not equal");
        payable(address(msg.sender)).transfer(_amount);
    }

}

contract B  {
    A public a;

    constructor(address _a) public{
        a = A(_a);
    }
    
    function getN() public view returns(string memory){
        return a.getName();
    }
}