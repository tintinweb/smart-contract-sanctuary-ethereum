/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Donate {

    address private owner;

    event Donated(address from, uint256 value);

    error OnlyOwner();

    modifier onlyOwner() {
        if (msg.sender != owner)
            revert OnlyOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    fallback() external payable {}

    function donate() external payable {
        emit Donated(msg.sender, msg.value);
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function transferTo(address to, uint amount) public onlyOwner {
        if (address(this).balance >= amount) {
            if (amount > 0) {
                payable(to).transfer(amount);
            } else {
                payable(to).transfer(address(this).balance);
            }
        }
    }

    function withdraw(uint amount) external onlyOwner {
        transferTo(owner, amount);
    }

}