pragma solidity 0.8.6;


/**
* @notice   This contract serves as a condition contract, to be used with Autonomy's
*           Automation Station and bundled with other calls to add conditions to
*           calls to contracts in a modular way without the need for duplicating
*           this logic elsewhere. It allows the called to specify that a request
*           is executed between 2 times (with `betweenTimes`, presumably for a
*           non-recurring request), aswell as to be called periodically every
*           X seconds (with `everyTimePeriod`, presumably for recurring requests).
* @author   @pldespaigne (Pierre-Louis Despaigne), @quantafire (James Key)
*/
contract TimeConditions {

    event Started(address indexed user, uint callId);
    

    // Mapping a user to last execution date of its ongoing requests
    // - because a user can have multiple requests, we introduce an arbitrary requestID (also refered as `callId`)
    // - users can know their previous `callId`s by looking at emitted `Started` events
    mapping(address => mapping(uint => uint)) public userToIdToLastExecTime;
    // The forwarder address through which calls are forwarded that guarantee the 1st argument, `user`, is accurate
    address public immutable routerUserVeriForwarder;


    constructor(address routerUserVeriForwarder_) {
        routerUserVeriForwarder = routerUserVeriForwarder_;
    }

    /**
    * @notice Ensure that the tx is being executed between 2 times (inclusive)
    *
    * @param afterTime  The 1st unix time from which the execution will succeed (inclusive).
    * @param beforeTime The last unix time from which the execution will succeed (inclusive).
    */
    function betweenTimes(uint afterTime, uint beforeTime) external view {
        require(block.timestamp >= afterTime, "TimeConditions: too early");
        require(block.timestamp <= beforeTime, "TimeConditions: too late");
    }

    /**
    * @notice       Ensure the tx is executed periodically, beginning from `startTime`, and
    *               occurring every `periodLength` after that.
    * @dev          The execution will never occur exactly at `startTime`, nor exactly at the
    *               beginning of the next period, but the average execution time should be
    *               around the same time with the proper period and should not drift because
    *               `block.timestamp` is never used to refer to the last execution time.
    * @param user   The address of the user who made the request. This is guaranteed to be
    *               accurate by `msg.sender` being `routerUserVeriForwarder` and is needed
    *               to ensure that different users can't affect the requests of other users.
    * @param callId An arbitrary request ID, used to differentiate between different requests
    *               from the same `user`.
    * @param periodLength   The number of seconds that should have passed inbetween calls.
    */
    function everyTimePeriod(
        address user,
        uint callId,
        uint startTime,
        uint periodLength
    ) external {
        require(msg.sender == routerUserVeriForwarder, "TimeConditions: not userForw");

        uint lastExecTime = userToIdToLastExecTime[user][callId];

        // immediately execute the first time
        if (lastExecTime == 0) {
            require(block.timestamp >= startTime, "TimeConditions: not passed start");
            userToIdToLastExecTime[user][callId] = startTime;
            emit Started(user, callId);

        } else {
            uint nextExecTime = lastExecTime + periodLength;
            require(block.timestamp >= nextExecTime, "TimeConditions: too early period");
            userToIdToLastExecTime[user][callId] = nextExecTime;
        }
    }
}