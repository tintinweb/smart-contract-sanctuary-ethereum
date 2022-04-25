/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

// @title Slink V2
// @author Yule Zhang, José Andrés Velasco Santos

contract SlinkV2 {

    event SLACreated(SLA sla);

    struct Service {
        string name;
        string description;
    }

    struct ServiceSpace {
        string name;
        string startTime;
        string endTime;
    }

    struct SLA {
        uint id;
        address customer;
        uint startDate;
        bool automaticRenewal;
        Service service;
        Service extraService;
        string serviceLevel;
        ServiceSpace serviceSpace;
        string license;
        string revisionReport;
        string billing;
        uint billingMethod;
        uint totalPrice;
    }

    address public provider;
    uint[] private slaIDs;
    mapping(uint => SLA) private slas;

    function findId(uint id) internal view returns(uint) {
        uint pos = slaIDs.length;
        uint i = 0;
        while (i < slaIDs.length && pos == slaIDs.length)  {
            if (slaIDs[i] == id) {
                pos = i;
            }
            i++;
        }
        return pos;
    }

    constructor() public {
        provider = msg.sender;
    }

    function addSLA(SLA memory sla) external checkNotExistID(sla.id) {
        slaIDs.push(sla.id);
        slas[sla.id] = sla;
        emit SLACreated(sla);
    }

    function getSLA(uint id) view external checkExistID(id) returns(SLA memory) {
        return slas[id];
    }

    modifier checkProvider() {
        require(provider == msg.sender, "Unauthorized");
        _;
    }

    modifier checkExistID(uint id) {
        require(findId(id) != slaIDs.length, "SLA id not exist");
        _;
    }

    modifier checkNotExistID(uint id) {
        require(findId(id) == slaIDs.length, "SLA id exist");
        _;
    }

}