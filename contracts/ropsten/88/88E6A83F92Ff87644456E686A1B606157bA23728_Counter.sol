// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Counter {

    event CountUpdated(uint count, address sender);
    
    uint public count;

    function inc() external {
        count += 1;
        emit CountUpdated(count, msg.sender);
    }

    function dec() external {
        require(count > 0, "Count is alrealdy 0");
        count -=1;
        emit CountUpdated(count, msg.sender);
    }
}