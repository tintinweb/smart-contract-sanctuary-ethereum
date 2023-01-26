/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero.");
        owner = newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == owner, "Only new owner can accept ownership.");
    }

    function proxy(address _to, bytes memory _data) public {
        require(_to != address(0), "Target address cannot be zero.");
        (bool success, bytes memory returnData) = _to.call{value: 0}(_data);
        require(success, "Failed to call target contract.");
    }

}