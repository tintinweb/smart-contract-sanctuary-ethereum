// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Homies {

    uint256 numWhitelister;
    uint256 maxWhitelisters;
    mapping(address => bool) homies;

    constructor(uint256 _maxWhitelisters){
        maxWhitelisters = _maxWhitelisters;
    }

    function whitelist() public {
        numWhitelister++;
        require(!homies[msg.sender], "Already Whitelisted");
        require(numWhitelister <= maxWhitelisters, "Whitelisting End");
        homies[msg.sender] = true;
    }

    function whitelisters(address whitelister) external view returns(bool) {
        return homies[whitelister];
    }

}