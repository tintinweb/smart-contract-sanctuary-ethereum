// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./Event.sol";

contract SingleAuthEvent is Event {
    address private immutable i_authAddress;
    EventStatus private s_eventStatus = EventStatus.OPEN;
    EventType private constant s_eventType = EventType.SINGLE_AUTH;

    event EventCompleted();

    constructor(address _authAddress) {
        i_authAddress = _authAddress;
    }

    function setStatus() public override {
        if (msg.sender == i_authAddress) {
            s_eventStatus = EventStatus.COMPLETED;
            emit EventCompleted();
        } else {
            revert("You are not authorized to complete this event");
        }
    }

    function getStatus() public view override returns (EventStatus) {
        return s_eventStatus;
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