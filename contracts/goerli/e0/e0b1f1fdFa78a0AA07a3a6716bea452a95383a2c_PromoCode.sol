/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PromoCode {
    uint256 public counter;
    string private promoCode;

    mapping(address => bool) public builders;

    constructor(string memory _promoCode) {
        promoCode = _promoCode;
    }

    function getPromocode(address builder) public view returns (string memory) {
        require(builders[builder], "You are not a builder!!!!!");
        return promoCode;
    }

    function iAmBulder() public {
        builders[msg.sender] = true;
        counter++;
    }
}