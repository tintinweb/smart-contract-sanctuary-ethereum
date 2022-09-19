/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

pragma solidity ^0.8.0;

contract ClassAttendance {
    uint256 public endTime = 1663563600;
    uint256 public counter = 0;

    uint256[] public studentIds;

    function check(uint256 _id) public {
        require(block.timestamp < endTime, "Exceed Time Limit");
        studentIds.push(_id);
        counter += 1;
    }

}