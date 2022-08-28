/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
 * @title Advanced and Efficient method of storing strings on the Blockchain
 * @dev Store & retrieve value in a variable
 */

contract AdvStrStorage {

    // For permission purposes
    address     m_owner;
    bool public m_isPaused;
    uint public m_index;

    // Event(s)
    event NewPhrase(uint indexed index, string phraseText);

    constructor() {
        m_owner = msg.sender;
    }

    function setPaused(bool _paused) public {
        require(msg.sender == m_owner, "You are not the owner, so you cannot pause it");
        m_isPaused = _paused;
    }

    /**
     * @dev Store value in variable
     * @param _phrase value to store
     */
    function addPhrase(string memory _phrase) public {
        require(m_isPaused == false, "This contract has been paused");
        emit NewPhrase(m_index, _phrase);
        m_index++;
    }

    /**
     * @dev Return value for the next available 'space' to store a new phrase
     * @return index corresponding to phrase which is a string type'
     */
    function retrievePhrase() public view returns (uint){
        return m_index;
    }
}