//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract BoxV2 {

    address public owner;
    uint256 public val;
    bool public initialized;
    address public admin;

    modifier onlyOwnerOrAdmin(){
        if(msg.sender!=owner && msg.sender!=admin) revert("not owner or admin");
        _;
    }

    modifier onlyOwner(){
        if(msg.sender!=owner) revert("not owner");
        _;
    }

    function incrementVal(uint256 _inc) external onlyOwnerOrAdmin {
        val += _inc;
    }

    function setAdmin(address _admin) external onlyOwner{
        admin = _admin;
    }

    uint256[49] private __gap;
}