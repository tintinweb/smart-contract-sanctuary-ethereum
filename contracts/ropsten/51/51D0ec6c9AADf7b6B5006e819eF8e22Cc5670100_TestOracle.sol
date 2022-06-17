/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// File: TestOracle.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TestOracle {

    uint256 private _price;

    /// @dev For testing purpouses the addres will be a uint256 
    mapping(uint256 => uint256) public nftPrices;

    constructor(uint256 price){
        _price = price;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    /// @notice The uint256 MUST be changed to address when deployed
    function setPrice(uint256 nftAddress, uint256 price) public{
        nftPrices[nftAddress] = price;
    }

    /// @notice The uint256 MUST be changed to address when deployed
    function getMappingPrice(uint256 number) public view returns (uint256){
        return nftPrices[number];
    }

}