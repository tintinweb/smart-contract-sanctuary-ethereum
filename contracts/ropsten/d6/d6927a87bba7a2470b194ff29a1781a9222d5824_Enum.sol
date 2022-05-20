/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Enum {
    enum Status {
        Pending,
        Shipped,
        Accepted,
        Rejected,
        Canceled
    }

    Status public instance;

    function get() public view returns (Status) {
        return instance;
    }

    function set(Status _status) public {
        instance = _status;
    }

    function cancel() public {
        instance = Status.Canceled;
    }

    function reset() public {
        delete instance;
    }
}