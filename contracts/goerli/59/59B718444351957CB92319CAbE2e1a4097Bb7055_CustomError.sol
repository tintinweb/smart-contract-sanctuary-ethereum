// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

contract CustomError {
    error SablierV2Lockup_Unauthorized(uint256 streamId, address caller);

    function trap() external {
        revert SablierV2Lockup_Unauthorized(1, msg.sender);
    }
}