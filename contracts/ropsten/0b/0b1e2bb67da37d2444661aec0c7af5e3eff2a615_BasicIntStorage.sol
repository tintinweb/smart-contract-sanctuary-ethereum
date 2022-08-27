/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/*
 * @title Basic Int Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

 contract BasicIntStorage {

    // attribute to be set or retrieved
    uint256     m_number;

    // For permission purposes
    address     m_owner;
    bool public m_isPaused;

    // Event(s)
    event IntChanged(uint256 oldNum, uint256 newNum);

    constructor() {
        m_owner = msg.sender;
    }

    function setPaused(bool _paused) public {
        require(msg.sender == m_owner, "You are not the owner, so you cannot pause it");
        m_isPaused = _paused;
    }

    /**
     * @dev Store value in variable
     * @param _num value to store
     */
    function updateInt(uint256 _num) public {
        require(m_isPaused == false, "This contract has been paused");
        emit IntChanged(m_number, _num);
        m_number = _num;
    }

    /**
     * @dev Return value 
     * @return value of 'm_number'
     */
    function retrieveInt() public view returns (uint256){
        return m_number;
    }

 }