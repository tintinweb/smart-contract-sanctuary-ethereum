// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { WeldChainAlpha006Structs as structs } from "./WeldChainAlpha006Structs.sol";
import { WeldChainAlpha006Library as lib } from "./WeldChainAlpha006Library.sol";
import { WeldChainAlpha006WeldLogLibrary as weldLogLib } from "./WeldChainAlpha006WeldLogLibrary.sol";
import { WeldChainAlpha006PagingLibrary as paging } from "./WeldChainAlpha006PagingLibrary.sol";
import { WeldChainAlpha006Registrations as WeldChainRegistrations } from "./WeldChainAlpha006Registrations.sol";
import { WeldChainAlpha006SetUps as WeldChainSetUps } from "./WeldChainAlpha006SetUps.sol";
import { WeldChainAlpha006WeldRegistration as WeldChainWeldRegistration } from "./WeldChainAlpha006WeldRegistration.sol";

/**
 * @title WeldChain release alpha 006 welding
 * @author Benjamin Roedell (Flexsible LLC)
 * @notice Publishes PII (Personally Identifiable Information) on the blockchain
 * @dev Publishes PII (Personally Identifiable Information) on the blockchain. Structs with the word private need to be removed before go-live
 * @custom:experimental This is an experimental contract.
 */
contract WeldChainAlpha006Welding {

    // See https://cloudweb2.aws.org/Certifications/Search/

    mapping(string => mapping(string => structs.WeldLogRecordDataPrivate[])) weldDataBySiteIdByWeldId;

    mapping(address => bool) private contractManagers;
    mapping(address => bool) private allowedCallers;

    WeldChainRegistrations weldChainRegistrations;
    WeldChainSetUps weldChainSetUps;
    WeldChainWeldRegistration weldChainWeldRegistration;

    constructor() {
        contractManagers[msg.sender] = true;
    }

    function initialize(
        address registrationsContractAddress, 
        address weldChainSetUpsAddress,
        address weldChainWeldRegistrationAddress,
        address[] memory allowedCallerAddresses
        ) public {
        require(contractManagers[msg.sender], "Unauthorized, sender must be contract manager");
        weldChainRegistrations = WeldChainRegistrations(registrationsContractAddress);
        weldChainSetUps = WeldChainSetUps(weldChainSetUpsAddress);
        weldChainWeldRegistration = WeldChainWeldRegistration(weldChainWeldRegistrationAddress);
        for (uint i = 0; i < allowedCallerAddresses.length; i++) {
            allowedCallers[allowedCallerAddresses[i]] = true;
        }
    }

    modifier onlyAllowedCallers() {
        require(allowedCallers[msg.sender], "Unauthorized, sender must be allowed contract");
        _;
    }

    /**
     * Get weld log records
     * @dev Internal use
     * @param siteId Unique id of the site
     * @param weldId Weld id
     * @return weldLogRecords Array of weld log records
     */
    function getWeldLogRecords(
        string memory siteId,
        string memory weldId
    ) onlyAllowedCallers public view returns(structs.WeldLogRecordDataPrivate[] memory weldLogRecords) {
        return weldDataBySiteIdByWeldId[siteId][weldId];
        //weldLogRecords = new structs.WeldLogRecordDataPrivate[]();
    }

    /**
     * Pay all weld log fees
     * @dev Call this with same parameters as get weld log
     * @param sender Address of original caller
     * @param siteId Unique id of the site
     */
    function payAllWeldLogFees(
        address sender,
        string memory siteId
    ) onlyAllowedCallers public {
        weldChainSetUps.requireValidSiteId(siteId);

        string[] memory weldIds = weldChainWeldRegistration.getAllWeldIds(siteId);
        uint totalFee = 0;
        for(uint i = 0; i < weldIds.length; i++) {
            totalFee += weldLogLib.getWeldLogFeeAndMarkPaid(weldDataBySiteIdByWeldId[siteId][weldIds[i]]);
        }

        uint currentBalance = weldChainSetUps.balanceOf(sender);

        require(currentBalance >= totalFee, "Not enough tokens");

        weldChainSetUps.decrementBalance(sender, sender, totalFee, false);
    }

    /**
     * Pay weld log fee
     * @dev Call this with same parameters as get weld log
     * @param sender Address of original caller
     * @param siteId Unique id of the site
     * @param weldId Weld id
     */
    function payWeldLogFee(
        address sender,
        string memory siteId,
        string memory weldId
    ) onlyAllowedCallers public {
        weldChainWeldRegistration.requireValidSiteAndWeldId(siteId, weldId);

        uint fee = weldLogLib.getWeldLogFeeAndMarkPaid(weldDataBySiteIdByWeldId[siteId][weldId]);

        uint currentBalance = weldChainSetUps.balanceOf(sender);

        require(currentBalance >= fee, "Not enough tokens");

        weldChainSetUps.decrementBalance(sender, sender, fee, false);
    }

    /**
     * Get all weld log fees
     * @param siteId Unique id of the site
     * @return tokens Decimal 18 token value
     */
    function getAllWeldLogFees(
        string memory siteId
    ) onlyAllowedCallers public view returns(uint tokens) {
        weldChainSetUps.requireValidSiteId(siteId);
        string[] memory weldIds = weldChainWeldRegistration.getAllWeldIds(siteId);
        return weldLogLib.getAllWeldLogFees(weldDataBySiteIdByWeldId[siteId], weldIds);
    }

    /**
     * Get weld log fee
     * @dev Call this with same parameters as get weld log
     * @param siteId Unique id of the site
     * @param weldId Weld id
     * @return tokens Decimal 18 token value
     */
    function getWeldLogFee(
        string memory siteId,
        string memory weldId
    ) onlyAllowedCallers public view returns(uint tokens) {
        weldChainWeldRegistration.requireValidSiteAndWeldId(siteId, weldId);

        return weldLogLib.getWeldLogFee(weldDataBySiteIdByWeldId[siteId][weldId]);
    }

    /**
     * Inspect weld
     * @param sender Address of original caller
     * @param inspectWeldInput Inspect weld information
     */
    function inspectWeld(
        address sender,
        structs.InspectWeldInput memory inspectWeldInput
    ) onlyAllowedCallers public {
        weldChainRegistrations.requireSenderToBeInspector(sender);
        weldChainWeldRegistration.requireValidSiteAndWeldId(inspectWeldInput.siteId, inspectWeldInput.weldId);

        lib.inspectWeldForSite(sender, inspectWeldInput, weldDataBySiteIdByWeldId[inspectWeldInput.siteId][inspectWeldInput.weldId]);

        weldChainSetUps.incrementBalance(sender, sender, 2, false);
    }

    /**
     * Record weld
     * @dev Used by welder to record a weld against a previously registered weld
     * @param sender Address of original caller
     * @param recordWeldInput Record weld information
     */
     function recordWeld(
         address sender,
         structs.RecordWeldInput memory recordWeldInput
     ) onlyAllowedCallers public {
        weldChainWeldRegistration.requireValidSiteWeldAndWpsId(recordWeldInput.siteId, recordWeldInput.weldId, recordWeldInput.wpsId);
        weldChainSetUps.requireSenderToBeApprovedWelder(sender, recordWeldInput.siteId);

        lib.recordWeldForSite(sender, recordWeldInput, weldDataBySiteIdByWeldId[recordWeldInput.siteId][recordWeldInput.weldId]);

        weldChainSetUps.incrementBalance(sender, sender, 5, false);
     }
}