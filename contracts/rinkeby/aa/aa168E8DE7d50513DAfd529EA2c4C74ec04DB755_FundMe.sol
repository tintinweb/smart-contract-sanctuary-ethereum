//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract FundMe {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}


    function fund(address payable _to, uint _amount) external {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");

    }
    
    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}