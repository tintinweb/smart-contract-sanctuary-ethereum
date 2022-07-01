// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DeliveryStatus {
    // now status is a user defined variable
    enum status {
        pending, // 0
        processing, // 1
        accepted, // 2
        rejected, // 3
        shipped, // 4
        out_for_delivery, // 5
        delivered // 6
    }

    // default will be 0 or pending in our case
    status public delivery_status;

    // as enum is a user defined variable we need to write name of the enum i.e status not enum
    function getStatus() public view returns (status) {
        return delivery_status;
    }

    function processing() public {
        delivery_status = status.processing;
    }

    function accept() public {
        delivery_status = status.accepted;
    }

    function reject() public {
        delivery_status = status.rejected;
    }

    function ship() public {
        delivery_status = status.shipped;
    }

    function out_for_delivery() public {
        delivery_status = status.out_for_delivery;
    }

    function delivered() public {
        delivery_status = status.delivered;
    }

    function set_status(status _index) public {
        delivery_status = _index;
    }

    // reset function simply put the default value of the variable which in our case will be pending (0)
    function reset_status() public {
        delete delivery_status;
    }
}