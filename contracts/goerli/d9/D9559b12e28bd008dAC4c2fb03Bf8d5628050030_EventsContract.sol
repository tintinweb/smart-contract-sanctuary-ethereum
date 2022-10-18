// SPDX-License-Identifier: MIT

pragma solidity ^0.4.17;

// this file is discussing and noting events
// events listen for transactions or 'events' that happen with the contract
// and will write those events to a log that is not accessable by the contract or
// any other contract.
// That is why events are much more gas effecient than using a function to do this
// https://docs.soliditylang.org/en/v0.8.17/contracts.html#events
// You can add the attribute indexed to up to three parameters which adds them
// to a special data structure known as “topics” instead of the data part of the log.
// All parameters without the indexed attribute are ABI-encoded into the data part of the log.

// Let's create a simple contract which we will look for events in our events.py file

contract EventsContract {
    event greeting(string name);

    function say() public view {
        greeting("drake");
    }
}