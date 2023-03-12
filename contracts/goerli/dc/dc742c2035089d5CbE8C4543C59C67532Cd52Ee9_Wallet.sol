// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Wallet {
    string public name = "Wallet";
    uint num;

    // write
    function setValue(uint _num) public {
        num = _num;
    }

    // read
    function getValue() public view returns(uint) {
        return num;
    }

    // write
    function sendEthContract() public payable {

    }

    // read
    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // read
    function sendEthUser(address _user) public payable {
        payable(_user).transfer(msg.value);
    }

    // read
    function accountBalance(address _address) public view returns(uint) {
        return (_address).balance;
    }
}