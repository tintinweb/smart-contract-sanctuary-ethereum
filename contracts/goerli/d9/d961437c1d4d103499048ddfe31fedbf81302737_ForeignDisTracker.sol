/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

contract ForeignDisTracker {
    uint256 private DisSold;
    mapping (address => bool) private _functionWhitelist;

    modifier onlyWhitelist() {
		require(_functionWhitelist[msg.sender] == true, "Address must be whitelisted to perform this");
		_;
	}

    constructor () public {
        _functionWhitelist[msg.sender] = true; 
    }

    function addWhitelist(address whitelisted) public onlyWhitelist() {
        _functionWhitelist[whitelisted] = true;
    }

    function GetDisSold() public view onlyWhitelist() returns (uint256) {
        return DisSold;
    }

    function SetDisSold(uint256 value) public onlyWhitelist() {
        DisSold = value;
    }
}