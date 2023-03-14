/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract AddressToTokenMap {

    address deployer;
    mapping(address => string) private addresses;

    constructor() {
        deployer = msg.sender;
    }

    // tokenAddress => tokenToUSD pair PriceFeed Address
    mapping(address => address) private priceFeedMap;

    function getAddress(address _key) public view returns (string memory) {
        return addresses[_key];
    }

    function _setAddress(address _key, string memory _value) public {
        require(msg.sender == deployer, "Not owner");
        addresses[_key] = _value;
    }

   function getPriceFeedMap(address _tokenAddress) public view returns(address) {
    return priceFeedMap[_tokenAddress];
   }

   function _setPriceFeedMap(address _tokenAddress, address _pairAddress) public {
        require(msg.sender == deployer, "Not owner");
        priceFeedMap[_tokenAddress] = _pairAddress;
   }
}