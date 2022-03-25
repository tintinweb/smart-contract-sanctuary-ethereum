// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Enum {
    // Enum representing shipping status
    enum Status {
        Pending,
        Shipped,
        Accepted,
        Rejected,
        Canceled
    }

    // Default value is the first element listed in
    // definition of the type, in this case "Pending"
    Status public status;
    string public name;

    // Returns uint
    // Pending  - 0
    // Shipped  - 1
    // Accepted - 2
    // Rejected - 3
    // Canceled - 4

    constructor(Status _status, string memory _name)  {
        status = _status;
        name = _name;
    }

    function get() public view returns (Status s, string memory n) {
        return (status, name);
    }


    function set(Status _status, string memory _name) public {
        status = _status;
        name = _name;
    }

    // You can update to a specific enum like this
    function cancel(string memory _name) public {
        status = Status.Canceled;
        name = _name;
    }

    // delete resets the enum to its first value, 0
    function reset(string memory _name) public {
        delete status;
        name = _name;
    }
}