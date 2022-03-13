/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract MopedShop {
    mapping (address => bool) buyers;
    uint256 public price = 0.1 ether;
    address public owner;
    address public shopAddress;
    bool fullyPaid;

    event ItemFullyPaid(uint _price, address _shopAddress);

    constructor() {
        owner = msg.sender;
        shopAddress = address(this);
    }

    function addBuyer(address _addr) public {
        require(owner == msg.sender, "You are not an owner!");
        buyers[_addr] = true;
    }

    function getBuyer(address _addr) public view returns(bool) {
        return buyers[_addr];
    }

    function getBalance() public view returns(uint256) {
        return shopAddress.balance;
    }

    function withdrawAll() public {
        require(owner == msg.sender && fullyPaid && shopAddress.balance > 0, "Rejected");
        address payable receiver = payable(msg.sender);
        receiver.transfer(shopAddress.balance);
    }

    receive() external payable {
        require(buyers[msg.sender] && msg.value <= price && !fullyPaid, "Rejected");
        if( getBalance() == price ) {
            fullyPaid = true;
            emit ItemFullyPaid(price, shopAddress);
        }
    } 
}