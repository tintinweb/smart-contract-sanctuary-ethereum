/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract sendeth {
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function getBalanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    function sendETH(address payable to, uint256 amount) public payable {
        address sender = msg.sender;

        require(sender == address(owner), "guid dcmm");

        (bool sent, bytes memory data) = to.call{gas:10000, value:amount}("");
        require(sent, "dcmm");
    }

    receive() external payable {}
    fallback() external payable {}
}