/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MockProofOfHumanity {
    mapping (address => bool) private addressRegistrationMap;

    /** @dev Return true if the submission is registered and not expired.
     *  @param _submissionID The address of the submission.
     *  @return Whether the submission is registered or not.
     */
    function isRegistered(address _submissionID) external view returns (bool) {
        return addressRegistrationMap[_submissionID];
    }

    function addRegistration(address _submissionID) external {
        addressRegistrationMap[_submissionID] = true;
    }

    function removeRegistration(address _submissionID) external {
        addressRegistrationMap[_submissionID] = false;
    }
}