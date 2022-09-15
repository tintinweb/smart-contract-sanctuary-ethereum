// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./Event.sol";

contract StoreWill {
    address private immutable i_recipient;
    uint private immutable i_storeHash;
    address[] private s_eventAddresses;
    bool private lock = true;
    address private immutable i_owner;

    constructor(address recipient, uint storeHash) {
        i_recipient = recipient;
        i_storeHash = storeHash;
        i_owner = msg.sender;
    }

    function checkAllEventsStatus() private view returns (bool) {
        address[] memory eventAddresses = s_eventAddresses;
        for (uint i = 0; i < eventAddresses.length; i++) {
            if (
                Event(eventAddresses[i]).getStatus() !=
                Event.EventStatus.COMPLETED
            ) {
                return false;
            }
        }
        return true;
    }

    function addEvent(address eventAddress) public {
        require(msg.sender == i_owner, "You are not the owner");
        require(lock, "You can't add events after the will is executed");
        s_eventAddresses.push(eventAddress);
    }

    function openLock() public {
        require(msg.sender == i_recipient, "You are not the owner");
        require(checkAllEventsStatus(), "Not all events are completed");
        lock = false;
    }

    function getFinalHash() public view returns (uint) {
        require(
            !lock,
            "You can't get the final hash until the will is executed"
        );
        require(
            msg.sender == i_recipient,
            "You are not the recipient of this will"
        );
        return i_storeHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

abstract contract Event {
    enum EventStatus {
        OPEN,
        COMPLETED
    }

    enum EventType {
        TIMED,
        VOTING,
        VETO,
        SINGLE_AUTH
    }

    EventStatus private s_eventStatus;
    EventType private s_eventType;

    function setStatus() public virtual;

    /* View Pure Functions */
    function getStatus() public view virtual returns (EventStatus) {
        return s_eventStatus;
    }
}