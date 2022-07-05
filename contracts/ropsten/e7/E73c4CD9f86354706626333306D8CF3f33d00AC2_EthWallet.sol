/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract EthWallet {

    mapping(address => uint) public balanceReceived;

    receive() external payable {
        balanceReceived[msg.sender] = msg.value;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getUserInfo(address _user) public view returns(uint) {
        return balanceReceived[_user];
    }

    function sendMoney() public payable {
        balanceReceived[msg.sender] += msg.value;
    }

    function withdrawAllMoney(uint _amount) external {
        require(balanceReceived[msg.sender] >= _amount);

        balanceReceived[msg.sender] -= _amount;
        (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
    }
}