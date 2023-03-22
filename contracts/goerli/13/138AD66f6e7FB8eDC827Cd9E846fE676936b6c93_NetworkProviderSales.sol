// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @title NetworkProvider Sales
/// @author Michael Aworoghene (000511874)
/// @notice This contract hold payment of network/internet service
///         and release the payment when there is zero downtime otherwise it
///         will split the payment between customer and service provider

contract NetworkProviderSales {
    mapping(address => uint) payment;

    address owner; // service provider
    uint cost = 30; // hard coded cost

    struct Service {
        uint amountPaid;
        uint startDate;
        uint duration;
        address customer;
        bool initiated;
    }

    Service activeService;

    string serviceRunningMessage =
        "Service duration based on the agreement is still running";

    constructor() {
        // Address that deploys contract will be the owner
        owner = msg.sender;
    }

    // Function accepts customers and initiates the active service using Service struct
    function payForService(address customer) public {
        activeService = Service(30, block.timestamp, 30 days, customer, true);
    }

    // Utility for spliting funds between owner(service provider) and customer
    function splitPayment() private {
        payment[owner] += activeService.amountPaid / 2;
        payment[activeService.customer] += activeService.amountPaid / 2;
    }

    // This function verifies the conditions of the contract and releases payment to the
    // networkProvider if the conditions are met.
    function releasePayment(uint networkDowntime) public {
        require(activeService.initiated);

        require(
            activeService.startDate + activeService.duration == block.timestamp,
            serviceRunningMessage
        );

        if (networkDowntime == 0) {
            payment[owner] += activeService.amountPaid;
        } else {
            splitPayment();
        }
    }
}