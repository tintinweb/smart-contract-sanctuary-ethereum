/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
contract MistoOracle {

    uint private currentWeiPrice;
    address private mistoContractAddress;

    constructor(address _mistoContractAddress) {
        mistoContractAddress = _mistoContractAddress;
    }

    modifier owningContractOnly {
        require(msg.sender == mistoContractAddress);
        _;
    }

    function setWeiPrice(uint weiPrice) public owningContractOnly {
        currentWeiPrice = weiPrice;
    }

    function getWeiPrice() public view returns(uint256) {
        return currentWeiPrice;
    }
}