/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnableContract {
    address public owner;

    event Paid(address indexed from, uint amount, uint timestamp);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        pay();
    }

    function pay() public payable {
        emit Paid(msg.sender, msg.value, block.timestamp);
    }

    modifier Ownable(address _to) {
        require(msg.sender == owner, "you are not an owner!");
        require(_to != address(0), "incorent address!");
        _;
    }

    function withdraw(address payable _to) external Ownable(_to) {
        _to.transfer(address(this).balance);
    }
}