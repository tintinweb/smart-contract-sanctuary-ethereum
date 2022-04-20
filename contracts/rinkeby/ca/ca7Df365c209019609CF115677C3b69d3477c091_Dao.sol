// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Dao {
    address public owner;
    address public vesting;

    constructor(address _owner, address _vesting) {
        owner = _owner;
        vesting = _vesting;
    }

    function callVestingClaim(uint96 amount) external {
        (bool success,) = vesting.call(
            abi.encodeWithSignature("claim(address,uint96)", address(this), amount)
        );
        require(success, "Success failed");
    }
}