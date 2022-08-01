// SPDX-License-Identifier: MIT
pragma solidity ^0.6;

/*
@title The Random Number Generator (RNG) Contract
@notice Dummy RNG contract to demonstrate the workings of the Lottery.sol contract. Mimicks the VRF contracts.
@author Jesper Kristensen
*/
contract RNG {
    bytes32 public current_request_id;
    uint256 numRequests;
    mapping(bytes32 => uint256) mapRequestIDToWaitTime;
    mapping(bytes32 => uint256) mapRequestIDToNumber;

    /// @notice make a request to receive an ID corresponding to a random number to be produced and can be claimed via getRandomNumber() later on.
    /// @return the request ID corresponding to a unique random number to be produced and can be claimed via getRandomNumber() later on.
    function request() external returns(bytes32) {
        current_request_id = bytes32(keccak256(abi.encodePacked(current_request_id, now)));
        mapRequestIDToNumber[current_request_id] = uint256(keccak256(abi.encodePacked(now, numRequests))) % 1e8;
        mapRequestIDToWaitTime[current_request_id] = now + 10;  // wait 10 seconds
        numRequests += 1;

        return current_request_id;
    }

    /// @notice claim the random number corresponding to the current request ID. If the random number is not ready yet, returns 0.
    /// @dev we assume that a valid random number is *not* zero.
    /// @param requestID current request ID to claim the random number corresponding to it.
    /// @return the random number corresponding to the current request ID. Returns 0 if the random number is not ready yet.
    function getRandomNumber(bytes32 requestID) external view returns(uint256) {
        require(mapRequestIDToWaitTime[requestID] > 0);

        uint256 the_random_number = 0;
        if (now > mapRequestIDToWaitTime[requestID]) {
            // the number is ready! Get it and return it
            the_random_number = mapRequestIDToNumber[requestID];

            assert(the_random_number > 0);
        }

        return the_random_number;
    }
}