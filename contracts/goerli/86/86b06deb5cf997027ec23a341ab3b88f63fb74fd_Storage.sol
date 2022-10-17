/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    event EventFired(string message);
    struct Event {
        string message;
    }
    Event[] public events;

    /**
     * @dev Store an event
     * @param eventMessage message of the event
     */
    function createEvent(string calldata eventMessage) public {
        events.push(Event({message: eventMessage}));
        emit EventFired(eventMessage);
    }
}