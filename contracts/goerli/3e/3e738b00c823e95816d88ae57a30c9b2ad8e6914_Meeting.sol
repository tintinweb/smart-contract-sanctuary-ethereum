// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Meeting {
    mapping(uint256 => string[]) private meetings;
    address private host;

    constructor() {
        host = msg.sender;
    }

    function addAttendee(uint256 meetingId, string calldata fullname) external {
        meetings[meetingId].push(fullname);
    }

    function deleteAttendee(uint256 meetingId, string calldata fullname)
        external
        returns (bool)
    {
        for (uint256 i = 0; i < meetings[meetingId].length; i++) {
            string memory currentAttendant = meetings[meetingId][i];

            if (
                keccak256(abi.encodePacked(currentAttendant)) ==
                keccak256(abi.encodePacked(fullname))
            ) {
                delete meetings[meetingId][i];
                return true;
            }
        }

        return false;
    }

    function getAttendee(uint256 meetingId)
        external
        view
        returns (string[] memory)
    {
        return meetings[meetingId];
    }
}