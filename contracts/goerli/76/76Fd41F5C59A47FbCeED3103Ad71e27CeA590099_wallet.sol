// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract wallet {
    string public name = "DigiWallet";
    uint number;

    function setValue(uint _number) public {
        number = _number;
    }

    function getValue() public view returns (uint) {
        return number;
    }

    function sendEthContract() public payable {}

    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function sendEthUser(address _user) public payable {
        (bool sent, ) = payable(_user).call{value: msg.value}("");
        require(sent);
    }

    function accountBalance(address _address) public view returns (uint) {
        return (_address).balance;
    }
}