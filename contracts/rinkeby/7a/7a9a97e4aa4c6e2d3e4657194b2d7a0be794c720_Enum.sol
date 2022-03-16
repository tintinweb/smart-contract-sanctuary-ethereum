/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity ^0.8.12;

contract Enum {
    enum Status {
        Pending, 
        Shipped,
        Accepted,
        Rejected,
        Canceled
    }

    Status public status;

    function get() public view returns(Status) {
        return status;
    }

    function set(Status _status) public {
        status = _status;
    }

    function cancel() public {
        status = Status.Canceled;
    }

    function reset() public {
        delete status;
    }
}