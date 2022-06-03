/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

contract EthDrops {

    mapping(address => bool) isOwner;

    constructor() {
        isOwner[msg.sender] = true;
    }

    modifier owner {
        require(isOwner[msg.sender] == true); _;
    }

    function addOwner(address user) public owner{
        isOwner[user] = true;
    }

    function withdrawETH(address reciever) public owner{
        uint contractBalance = address(this).balance;
        payable(reciever).transfer(contractBalance);
    }

    function airDropEth(address[] memory accounts, uint256[] memory amounts) public owner {
        require(accounts.length == amounts.length, "Holders and amounts length must be the same");
        for(uint256 index = 0; index < accounts.length; index++){
            address account = accounts[index];
            uint256 amount = amounts[index];
            payable(account).transfer(amount);
        }
    }

    receive() external payable {}
    
}