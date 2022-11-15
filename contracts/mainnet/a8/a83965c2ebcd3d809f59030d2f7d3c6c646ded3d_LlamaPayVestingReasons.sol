// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

interface VestingContract {
    function admin() external view returns (address);
}

error NOT_ADMIN();

contract LlamaPayVestingReasons {
    mapping(address => string) public reasons;

    function addReason(address _vestingContract, string memory _reason)
        external
    {
        if (VestingContract(_vestingContract).admin() != msg.sender)
            revert NOT_ADMIN();
        reasons[_vestingContract] = _reason;
    }
}