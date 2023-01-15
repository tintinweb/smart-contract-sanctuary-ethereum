/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// File: hash.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.8;

contract ethers {
    string public name = "sudeep";
    uint num;

    function getValue() public view returns(uint) {
        return num;
    }

    function setValue(uint _num) public {
        num = _num;
    }

    function sendEthContract() public payable {}

    function contractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function sendEthUser (address _user) public payable {
        payable(_user).transfer(msg.value);
    }

    function accountBalance(address _address) public view returns(uint) {
        return (_address).balance;
    }
}