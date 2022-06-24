/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HelloWorldContract {

    address payable public owner; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 private key(пароль) -> public key -> address(логин)
    mapping(address=>string) public messages;

    constructor() {
        owner = payable(msg.sender);
    }

    function addMessage(string memory _message) public payable  {
        require(msg.value >= 0.01 ether, "Oooops, not enough ether!");
        messages[msg.sender] = _message;
    }

    function getMessageByAddress(address _from) public view returns (string memory) {
        return messages[_from];
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawCash() public {
        owner.transfer(getContractBalance());
    }

}