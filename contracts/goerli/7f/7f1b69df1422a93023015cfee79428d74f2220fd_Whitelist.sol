/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.16;

contract Whitelist {

    address public owner;
    uint8 public maxWhitelisted;
    uint8 public numberWhitelisted;

    constructor(uint8 _maxWhitelisted) {
        owner = msg.sender;
        maxWhitelisted = _maxWhitelisted;
    }

    mapping(address => bool) public whitelisted;

    function addToWhitelist() external returns(bool success) {
        
        require(!whitelisted[msg.sender], "Address already whitelisted!");
        require(numberWhitelisted < maxWhitelisted, "Max whitelist reached!");

        whitelisted[msg.sender] = true;
        numberWhitelisted += 1;
        return true;
    }

    function removeFromWhitelist(address _addr) external returns(bool success) {
        require(whitelisted[_addr], "Address hasn't been whitelisted!");
        require(msg.sender == owner, "Only owner can de-whitelist!");
    
        whitelisted[_addr] = false;
        numberWhitelisted -= 1;

        return true;
    }
}