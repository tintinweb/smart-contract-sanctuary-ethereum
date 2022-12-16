/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PromoCode {
    string private promoCode;
    address private manager;
    mapping(address => bool) public builders;

    constructor() {
        manager = msg.sender;
    }

    function getPromocode() public view returns (string memory) {
        require(builders[msg.sender], "You are not a builder!!!!!");
        return promoCode;
    }

    function setPromoCode(string memory newPromoCode) public {
        require(msg.sender == manager, "You are not a manager");
        promoCode = newPromoCode;
    }

    function iAmBulder() public {
        builders[msg.sender] = true;
    }
}