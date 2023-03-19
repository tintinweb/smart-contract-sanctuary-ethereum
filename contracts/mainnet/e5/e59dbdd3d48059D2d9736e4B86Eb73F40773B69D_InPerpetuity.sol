/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.18;

contract InPerpetuity {

    address payable owner;
    string name = "In Perpetuity";
    string hash = "3841184ac44ed1ca31375cb2742dde47bb916d8e6";
    uint value = 0;
        
    constructor() {
        owner = payable(msg.sender); // Set the owner to sender address 
    }

    function setValue(uint newValue) public {
        require(msg.sender == owner, "Caller is not owner");
        value = newValue;
    }

    function transferOwner() payable public {
        require(value > 0, "Value still set to 0");
        require(msg.value >= value, "Submitted value not high enough");
        owner.transfer(msg.value);
        owner = payable(msg.sender);
	value = 0;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}