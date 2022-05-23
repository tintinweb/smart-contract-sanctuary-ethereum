/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier:MIT

pragma solidity >=0.7.6;

interface IFreemoney {
    function getMoney(uint256 numTokens) external;
    function enterHallebarde() external;
    function reset() external;
    function getMembershipStatus(address memberAddress) external view returns (bool);
    function transfer(address receiver, uint256 numTokens) external returns (bool); 
}

contract Main {
    address private constant DataContractAddress = 0xb8c77090221FDF55e68EA1CB5588D812fB9f77D6;

    function reset() public {
        return IFreemoney(DataContractAddress).reset();
    }
    function getMoney(uint256 numTokens) public {
        return IFreemoney(DataContractAddress).getMoney(numTokens);
    }
    function enterHallebarde() public {
        return IFreemoney(DataContractAddress).enterHallebarde();
    }
}