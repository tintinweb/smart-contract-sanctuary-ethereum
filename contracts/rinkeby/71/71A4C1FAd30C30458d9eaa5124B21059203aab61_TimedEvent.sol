// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "./Event.sol";

contract TimedEvent is Event {
    uint public immutable unlockTime;
    EventStatus private s_eventStatus = EventStatus.OPEN;
    EventType private constant s_eventType = EventType.TIMED;

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );
        unlockTime = _unlockTime;
    }

    // ToDo: Add chainlink oracle to get current time and trigger event automatically
    function setStatus() public override {
        if (block.timestamp >= unlockTime) {
            s_eventStatus = EventStatus.COMPLETED;
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