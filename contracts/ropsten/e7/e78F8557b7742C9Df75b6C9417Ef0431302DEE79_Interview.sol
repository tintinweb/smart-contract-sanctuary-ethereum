/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
// compiler: 0.8.7+commit.e28d00a7

pragma solidity >=0.7.0 <0.9.0;

contract Interview {

    mapping(address => uint256) submissions;

    /**
     * @dev Store value in variable
     * @param number value to store
     */
    function store(uint256 number) public {
        submissions[msg.sender] = number;
    }

    /**
     * @dev Return value 
     * @return value of previous submissions
     */
    function viewSubmission(address candidate) public view returns (uint256){
        return submissions[candidate];
    }

}