// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Dao {
    address public owner;
    address public vesting;

    constructor(address _owner) {
        owner = _owner;
    }

    function setVestingAddress(address _vesting) external {
        require(msg.sender == owner, "Not allowed");
        vesting = _vesting;        
    }

    function callVestingClaim(uint96 amount) external {
        require(msg.sender == owner, "Not allowed");
        (bool success,) = vesting.call(
            abi.encodeWithSignature("claim(address,uint96)", address(this), amount)
        );
        require(success, "Success failed");
    }
}