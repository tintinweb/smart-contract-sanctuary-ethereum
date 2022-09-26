/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

contract MyBank {

    address public owner;
    mapping (address => uint) balances;

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function totalSupply() public view returns(uint) {
        return address(this).balance;
    }

    function balanceOf(address _user) public view returns(uint) {
        return balances[_user];
    }

    function withdraw() public {
        uint balance = balances[msg.sender];
        require(balance > 0, "no balance");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "withdraw failed");
    }
}