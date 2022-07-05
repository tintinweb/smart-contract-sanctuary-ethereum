/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract EthWallet {

    address admin;
    mapping(address => uint) public balanceReceived;
    uint minimumWithdraw = 0.005 ether;

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {
        uint fee = msg.value / 100;
        uint depositAmount = msg.value - fee;
        
        balanceReceived[admin] += fee;
        balanceReceived[msg.sender] += depositAmount;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getUserInfo(address _user) public view returns(uint) {
        return balanceReceived[_user];
    }

    function userWithdraw(uint _amount) external {
        require(balanceReceived[msg.sender] >= _amount, "There is not enough Eth in your balance.");
        require(_amount >= minimumWithdraw, "Withdraw amount must be above the minimum");

        balanceReceived[msg.sender] -= _amount;
        (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
    }

    function transferOwnership() external {
        require(msg.sender == admin, "Ownership must be tranfered by current owner.");

        admin = msg.sender;
    }
}