/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

// @title Slink V2
// @author Yule Zhang, José Andrés Velasco Santos

contract SlinkV2 {

    event ServiceCreated(uint serviceId, string name, string description);
    event ExtraServiceCreated(uint extraServiceId, string name, string description);
    event ServiceSpaceCreated(uint serviceSpaceId, string name, string startTime, string endTime);
    event LicenseCreated(uint licenseId, string name);
    event RevisionReportCreated(uint licenseId, string name);
    event BillingCreated(uint licenseId, string name);
    event BillingMethodCreated(uint licenseId, string name);

    event SLACreated(
        uint slaId,
        address customer,
        uint startDate,
        bool automaticRenewal,
        uint service,
        uint extraService,
        uint serviceSpace,
        uint license,
        uint revisionReport,
        uint billing,
        uint billingMethod,
        uint totalPrice
    );

    struct Service {
        uint serviceId;
        string name;
        string description;
    }

    struct ServiceSpace {
        uint serviceSpaceId;
        string name;
        string startTime;
        string endTime;
    }

    struct License {
        uint licenseId;
        string name;
    }

    struct RevisionReport {
        uint revisionReportId;
        string name;
    }

    struct Billing {
        uint billingId;
        string name;
    }

    struct BillingMethod {
        uint billingMethodId;
        string name;
    }

    struct SLA {
        uint id;
        address customer;
        uint startDate;
        bool automaticRenewal;
        uint service;
        uint extraService;
        uint serviceSpace;
        uint license;
        uint revisionReport;
        uint billing;
        uint billingMethod;
        uint totalPrice;
    }

    address public provider;
    string public serviceLevel;

    uint[] private serviceIds;
    mapping(uint => Service) public services;

    uint[] private extraServiceIds;
    mapping(uint => Service) public extraServices;

    uint[] private serviceSpaceIds;
    mapping(uint => ServiceSpace) public serviceSpaces;

    uint[] private licenseIds;
    mapping(uint => License) public licenses;

    uint[] private revisionReportIds;
    mapping(uint => RevisionReport) public revisionReports;

    uint[] private billingIds;
    mapping(uint => Billing) public billings;

    uint[] private billingMethodIds;
    mapping(uint => BillingMethod) public billingMethods;

    uint[] private slaIDs;
    mapping(uint => SLA) private slas;

    function findServiceId(uint id) internal view returns(uint) {
        uint pos = serviceIds.length;
        uint i = 0;
        while (i < serviceIds.length && pos == serviceIds.length)  {
            if (serviceIds[i] == id) {
                pos = i;
            }
            i++;
        }
        return pos;
    }

    function findExtraServiceId(uint id) internal view returns(uint) {
        uint pos = extraServiceIds.length;
        uint i = 0;
        while (i < extraServiceIds.length && pos == extraServiceIds.length)  {
            if (extraServiceIds[i] == id) {
                pos = i;
            }
            i++;
        }
        return pos;
    }

    function findServiceSpaceId(uint id) internal view returns(uint) {
        uint pos = serviceSpaceIds.length;
        uint i = 0;
        while (i < serviceSpaceIds.length && pos == serviceSpaceIds.length)  {
            if (serviceSpaceIds[i] == id) {
                pos = i;
            }
            i++;
        }
        return pos;
    }

    function findLicenseId(uint id) internal view returns(uint) {
        uint pos = licenseIds.length;
        uint i = 0;
        while (i < licenseIds.length && pos == licenseIds.length)  {
            if (licenseIds[i] == id) {
                pos = i;
            }
            i++;
        }
        return pos;
    }

    function findRevisionReportId(uint id) internal view returns(uint) {
        uint pos = revisionReportIds.length;
        uint i = 0;
        while (i < revisionReportIds.length && pos == revisionReportIds.length)  {
            if (revisionReportIds[i] == id) {
                pos = i;
            }
            i++;
        }
        return pos;
    }

    function findBillingId(uint id) internal view returns(uint) {
        uint pos = billingIds.length;
        uint i = 0;
        while (i < billingIds.length && pos == billingIds.length)  {
            if (billingIds[i] == id) {
                pos = i;
            }
            i++;
        }
        return pos;
    }

    function findBillingMethodId(uint id) internal view returns(uint) {
        uint pos = billingMethodIds.length;
        uint i = 0;
        while (i < billingMethodIds.length && pos == billingMethodIds.length)  {
            if (billingMethodIds[i] == id) {
                pos = i;
            }
            i++;
        }
        return pos;
    }

    function findSLAId(uint id) internal view returns(uint) {
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

    constructor(string memory _serviceLevel) public {
        provider = msg.sender;
        serviceLevel = _serviceLevel;
    }

    function addService(Service memory service) external checkProvider checkNotExistService(service.serviceId) {
        serviceIds.push(service.serviceId);
        services[service.serviceId] = service;
        emit ServiceCreated(service.serviceId, service.name, service.description);
    }

    function addExtraService(Service memory extraService) external checkProvider checkNotExistExtraService(extraService.serviceId) {
        extraServiceIds.push(extraService.serviceId);
        extraServices[extraService.serviceId] = extraService;
        emit ExtraServiceCreated(extraService.serviceId, extraService.name, extraService.description);
    }

    function addServiceSpace(ServiceSpace memory serviceSpace) external checkProvider checkNotExistServiceSpace(serviceSpace.serviceSpaceId) {
        serviceSpaceIds.push(serviceSpace.serviceSpaceId);
        serviceSpaces[serviceSpace.serviceSpaceId] = serviceSpace;
        emit ServiceSpaceCreated(serviceSpace.serviceSpaceId, serviceSpace.name, serviceSpace.startTime, serviceSpace.endTime);
    }

    function addLicense(License memory license) external checkProvider checkNotExistLicense(license.licenseId) {
        licenseIds.push(license.licenseId);
        licenses[license.licenseId] = license;
        emit LicenseCreated(license.licenseId, license.name);
    }

    function addRevisionReport(RevisionReport memory revisionReport) external checkProvider checkNotExistRevisionReport(revisionReport.revisionReportId) {
        revisionReportIds.push(revisionReport.revisionReportId);
        revisionReports[revisionReport.revisionReportId] = revisionReport;
        emit RevisionReportCreated(revisionReport.revisionReportId, revisionReport.name);
    }

    function addBilling(Billing memory billing) external checkProvider checkNotExistBilling(billing.billingId) {
        billingIds.push(billing.billingId);
        billings[billing.billingId] = billing;
        emit BillingCreated(billing.billingId, billing.name);
    }

    function addBillingMethod(BillingMethod memory billingMethod) external checkProvider checkNotExistBillingMethod(billingMethod.billingMethodId) {
        billingMethodIds.push(billingMethod.billingMethodId);
        billingMethods[billingMethod.billingMethodId] = billingMethod;
        emit BillingMethodCreated(billingMethod.billingMethodId, billingMethod.name);
    }

    function addSLA(SLA memory sla) external checkProvider checkNotExistID(sla.id) {
        slaIDs.push(sla.id);
        slas[sla.id] = sla;
        emit SLACreated(
            sla.id,
            sla.customer,
            sla.startDate,
            sla.automaticRenewal,
            sla.service,
            sla.extraService,
            sla.serviceSpace,
            sla.license,
            sla.revisionReport,
            sla.billing,
            sla.billingMethod,
            sla.totalPrice
        );
    }

    function getSLA(uint id) view external checkExistID(id) returns(SLA memory) {
        return slas[id];
    }

    modifier checkProvider() {
        require(provider == msg.sender, "Unauthorized");
        _;
    }

    modifier checkExistID(uint id) {
        require(findSLAId(id) != slaIDs.length, "SLA id not exist");
        _;
    }

    modifier checkNotExistID(uint id) {
        require(findSLAId(id) == slaIDs.length, "SLA id exist");
        _;
    }

    modifier checkNotExistService(uint id) {
        require(findServiceId(id) == serviceIds.length, "Service id exist");
        _;
    }

    modifier checkNotExistExtraService(uint id) {
        require(findExtraServiceId(id) == extraServiceIds.length, "Extra service id exist");
        _;
    }

    modifier checkNotExistServiceSpace(uint id) {
        require(findServiceSpaceId(id) == serviceSpaceIds.length, "Service space id exist");
        _;
    }

    modifier checkNotExistLicense(uint id) {
        require(findLicenseId(id) == licenseIds.length, "License id exist");
        _;
    }

    modifier checkNotExistRevisionReport(uint id) {
        require(findRevisionReportId(id) == revisionReportIds.length, "Revision report id exist");
        _;
    }

    modifier checkNotExistBilling(uint id) {
        require(findBillingId(id) == billingIds.length, "Billing id exist");
        _;
    }

    modifier checkNotExistBillingMethod(uint id) {
        require(findBillingMethodId(id) == billingMethodIds.length, "Billing method id exist");
        _;
    }

}