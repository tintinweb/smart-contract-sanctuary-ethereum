// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract IndexTest {
    address public owner;
    address public codexswapAddresses;
    address public codexdelegateAddresses;
    address public codexvalidationAddresses;

    constructor() {
      owner = msg.sender;
    }

    function setcodedAddress(address _codexswap,address _codexdelegate,address _codexvalidation) public onlyOwner {
        codexswapAddresses = _codexswap;
        codexdelegateAddresses = _codexdelegate;
        codexvalidationAddresses = _codexvalidation;
    }

    function getcodedAddress() public view returns (address _codexswap,address _codexdelegate,address _codexvalidation) {
        return (codexswapAddresses,codexdelegateAddresses,codexvalidationAddresses);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}