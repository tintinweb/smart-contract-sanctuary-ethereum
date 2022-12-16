/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PromoCode {
    uint256 public counter;
    bytes32 private promoCode;

    mapping(address => bool) public builders;

    constructor(string memory _promoCode) {
        promoCode = keccak256(abi.encodePacked(_promoCode)) ;
    }

    function getPromocode(address builder) public view returns (bytes32 ) {
        require(builders[builder], "You are not a builder!!!!!");
        return promoCode;
    }

    function iAmBulder() public {
        builders[msg.sender] = true;
        counter++;
    }
}