/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

// @title Slink V1
// @author Yule Zhang, José Andrés Velasco Santos

contract SlinkV1 {

    event SLACreated(uint slaId);
    event SLAGetted(uint slaId);

    struct Service {
        string name;
        string description;
        uint price;
        uint pricePeriodicity;
    }

    struct ServiceSpace {
        string name;
        string startTime;
        string endTime;
        uint price;
        uint pricePeriodicity;
    }

    struct RevisionReport {
        string name;
        uint price;
        uint pricePeriodicity;
    }

    struct Billing {
        string name;
        uint periodicity;
    }

    struct SLA {
        address customer;
        uint startDate;
        bool automaticRenewal;
        Service service;
        Service extraService;
        string serviceLevel;
        ServiceSpace serviceSpace;
        string license;
        RevisionReport revisionReport;
        Billing billing;
        uint billingMethod;
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

    function addSLA(uint id, uint startDate, bool automaticRenewal, Service memory service, Service memory extraService, string memory serviceLevel, ServiceSpace memory serviceSpace, string memory license, RevisionReport memory revisionReport, Billing memory billing, uint billingMethod) external checkNotExistID(id) {
        slaIDs.push(id);
        slas[id] = SLA(msg.sender, startDate, automaticRenewal, service, extraService, serviceLevel, serviceSpace, license, revisionReport, billing, billingMethod);
        emit SLACreated(id);
    }

    function getSLA(uint id) external checkExistID(id)  returns(SLA memory) {
        emit SLAGetted(id);
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