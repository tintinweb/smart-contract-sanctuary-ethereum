/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: GPL-3.0
/**
 *  @authors: []
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.1;

/**
 * @title Aggregate Blockchain events
 * @dev Continous stream of CIDS
 */
contract Event {

    address public bot;

    constructor() {
        bot = msg.sender;
    }

    event Update(string _CID);

    function update(string calldata _CID) external {
        require(msg.sender == bot, "Only the bot can call this.");
        emit Update(_CID);
    }
}