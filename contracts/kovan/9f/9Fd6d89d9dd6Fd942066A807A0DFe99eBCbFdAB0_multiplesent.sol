/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract multiplesent {
    mapping(address => uint256) public sender;

    function registration(uint256 userType) public {
        if (userType == 1) {
            sender[msg.sender] = 1;
        } else {}
    }

    function _transfer(address payable receiverAddr, uint256 receiverAmnt)
        private
    {
        receiverAddr.transfer(receiverAmnt);
    }

    function transfer(
        address payable[] memory to,
        uint256[] memory amount
    ) public payable {
        uint256 totalsend = msg.value;
        require(sender[msg.sender] == 1, "");
        require(to.length == amount.length, "");
        uint256 total;
        for (uint256 i = 0; i < amount.length; i++) {
            total += amount[i];
        }
        require(totalsend >= total, "enter higher amount");
        for (uint256 i = 0; i < to.length; i++) {
            totalsend -= amount[i];
            _transfer(to[i], amount[i]);
        }
    }

    function balance() public view returns (uint256) {
        return msg.sender.balance;
    }
}