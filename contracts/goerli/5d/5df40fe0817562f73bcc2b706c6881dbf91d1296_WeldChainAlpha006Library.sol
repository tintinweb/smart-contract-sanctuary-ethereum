// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { WeldChainAlpha006Structs as structs } from "./WeldChainAlpha006Structs.sol";

/**
 * @title WeldChain release alpha 006 library
 * @author Benjamin Roedell (Flexsible LLC)
 * @notice Publishes PII (Personally Identifiable Information) on the blockchain
 * @dev Publishes PII (Personally Identifiable Information) on the blockchain. Structs with the word private need to be removed before go-live
 * @custom:experimental This is an experimental contract.
 */
library WeldChainAlpha006Library {

    /**
     * Update certificate approval data
     * @dev Generic function for updating certification approval data
     * @param certificationNumbers certification number from call (from sender)
     * @param storageCertifications storage certification approvals
     */
    function updateCertificationNumbers(
        string[] memory certificationNumbers, 
        structs.CertificationApprovalData[] storage storageCertifications
    ) public {
        for (uint i = 0; i < storageCertifications.length; i++) {
            structs.CertificationApprovalData storage storageCertificationData = storageCertifications[i];
            string storage storageCertificationNummber = storageCertificationData.certificationNumber;

            bool found = false;
            for (uint j = 0; j < certificationNumbers.length; j++) {
                string memory certificationNumberFromCall = certificationNumbers[j];

                if (keccak256(bytes(storageCertificationNummber)) == keccak256(bytes(certificationNumberFromCall))
                ) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                storageCertifications[i] = storageCertifications[storageCertifications.length - 1];
                delete storageCertifications[storageCertifications.length - 1];
                storageCertifications.pop();
            }
        }

        for (uint i = 0; i < certificationNumbers.length; i++) {
            string memory certificationNumberFromCall = certificationNumbers[i];

            bool found = false;
            for (uint j = 0; j < storageCertifications.length; j++) {
                structs.CertificationApprovalData storage storageCertificationData = storageCertifications[j];
                string storage storageCertificationNummber = storageCertificationData.certificationNumber;
                if (keccak256(bytes(storageCertificationNummber)) == keccak256(bytes(certificationNumberFromCall))
                ) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                storageCertifications.push();
                structs.CertificationApprovalData storage storageCertification = storageCertifications[storageCertifications.length - 1];
                storageCertification.certificationNumber = certificationNumberFromCall;
            }
        }
    }

    function updateCertificationApprovalData(
        address sender, 
        string[] memory certificationNumbersFromCall,
        structs.CertificationApprovalData[] storage certificationDataList
    ) public {
        for (uint i = 0; i < certificationNumbersFromCall.length; i++) {
            string memory certificationNumberFromCall = certificationNumbersFromCall[i];

            for (uint j = 0; j < certificationDataList.length; j++) {
                structs.CertificationApprovalData storage certificationData = certificationDataList[j];

                if (keccak256(bytes(certificationNumberFromCall)) == keccak256(bytes(certificationData.certificationNumber))
                ) {
                    certificationData.approvedBy = sender;
                    break;
                }
            }
        }

        for (uint i = 0; i < certificationDataList.length; i++) {
            structs.CertificationApprovalData storage certificationData = certificationDataList[i];
            
            bool found = false;
            for (uint j = 0; j < certificationNumbersFromCall.length; j++) {
                string memory certificationNumberFromCall = certificationNumbersFromCall[j];

                if (keccak256(bytes(certificationNumberFromCall)) == keccak256(bytes(certificationData.certificationNumber))
                ) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                certificationData.approvedBy = address(0);
            }
        }
    }

    /**
     * Require sender to be a valid engineer
     * @dev Verifies that sender is an engineer with all certifications current
     */
    function requireSenderToBeEngineer(structs.EngineerDataPrivate storage engineerDataPrivate) public view {
        bool engineerHasCertifications = engineerDataPrivate.certifications.length > 0;
        require(engineerHasCertifications, "Sender has no certifications");

        bool allCertificationsApproved = true;
        for (uint i = 0; i < engineerDataPrivate.certifications.length; i++) {
            structs.CertificationApprovalData storage certificationData = engineerDataPrivate.certifications[i];
            if (certificationData.approvedBy == address(0)) {
                allCertificationsApproved = false;
                break;
            }
        }
        require(allCertificationsApproved, "Sender has certifications that have not been approved");
    }

    /**
     * Require sender to be a valid inspector
     * @dev Verifies that sender is an inspector with all certifications current
     */
    function requireSenderToBeInspector(structs.InspectorDataPrivate storage inspectorDataPrivate) public view {
        bool inspectorHasCertifications = inspectorDataPrivate.certifications.length > 0;
        require(inspectorHasCertifications, "Sender has no certifications");

        bool allExpirationDatesAreSet = true;
        bool allExpirationDatesAreInTheFuture = true;
        for (uint i = 0; i < inspectorDataPrivate.certifications.length; i++) {
            structs.AwsCertificationData storage certificationData = inspectorDataPrivate.certifications[i];
            if (certificationData.expirationDate == 0) {
                allExpirationDatesAreSet = false;
                break;
            }
            if (block.timestamp > certificationData.expirationDate) {
                allExpirationDatesAreInTheFuture = false;
                break;
            }
        }
        require(allExpirationDatesAreSet, "Sender has unset certification expiration(s)");
        require(allExpirationDatesAreInTheFuture, "Sender has expired certification(s)");
    }

    /**
     * Checks sender to be a valid inspector
     * @dev Verifies that sender is an inspector with all certifications current
     */
    function hasValidInspectorCertifications(structs.InspectorDataPrivate storage inspectorDataPrivate) public view returns (bool isInspector) {
        bool inspectorHasCertifications = inspectorDataPrivate.certifications.length > 0;
        if (!inspectorHasCertifications) {
            return false;
        }

        for (uint i = 0; i < inspectorDataPrivate.certifications.length; i++) {
            structs.AwsCertificationData storage certificationData = inspectorDataPrivate.certifications[i];
            if (certificationData.expirationDate == 0) {
                return false;
            }
            if (block.timestamp > certificationData.expirationDate) {
                return false;
            }
        }

        return true;
    }

    /**
     * Update inspector certification information based on https://cloudweb2.aws.org/Certifications/Search/
     * @dev Used for updating expiration dates
     * @param inspectorCertificationFromCall inspector certification input from call
     * @param inspectorDataPrivate inspector storage data to update
     */
    function updateAwsCertificationData(
        structs.InspectorCertificationData memory inspectorCertificationFromCall,
        structs.InspectorDataPrivate storage inspectorDataPrivate
    ) public {
        for (uint i = 0; i < inspectorCertificationFromCall.certifications.length; i++) {
            structs.AwsCertificationData memory certificationDataFromCall = inspectorCertificationFromCall.certifications[i];

            for (uint j = 0; j < inspectorDataPrivate.certifications.length; j++) {
                structs.AwsCertificationData storage certificationData = inspectorDataPrivate.certifications[j];

                if (keccak256(bytes(certificationDataFromCall.certificationNumber)) == keccak256(bytes(certificationData.certificationNumber))
                ) {
                    certificationData.expirationDate = certificationDataFromCall.expirationDate;
                }
            }
        }
    }

    /**
     * Update inspector certification numbers
     * @notice Publishes PII (Personally Identifiable Information) on the blockchain
     * @dev Used for updating certification numbers
     * @param certificationNumbers Inspector certification numbers input from call
     * @param storageCertifications Inspector certification data to update
     */
    function updateInspectorCertificationNumbers(
        string[] memory certificationNumbers,
        structs.AwsCertificationData[] storage storageCertifications
    ) public {
        for (uint i = 0; i < storageCertifications.length; i++) {
            structs.AwsCertificationData storage storageCertificationData = storageCertifications[i];
            string storage storageCertificationNummber = storageCertificationData.certificationNumber;

            bool found = false;
            for (uint j = 0; j < certificationNumbers.length; j++) {
                string memory certificationNumberFromCall = certificationNumbers[j];

                if (keccak256(bytes(storageCertificationNummber)) == keccak256(bytes(certificationNumberFromCall))
                ) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                storageCertifications[i] = storageCertifications[storageCertifications.length - 1];
                delete storageCertifications[storageCertifications.length - 1];
                storageCertifications.pop();
            }
        }

        for (uint i = 0; i < certificationNumbers.length; i++) {
            string memory certificationNumberFromCall = certificationNumbers[i];

            bool found = false;
            for (uint j = 0; j < storageCertifications.length; j++) {
                structs.AwsCertificationData storage storageCertificationData = storageCertifications[j];
                string storage storageCertificationNummber = storageCertificationData.certificationNumber;
                if (keccak256(bytes(storageCertificationNummber)) == keccak256(bytes(certificationNumberFromCall))
                ) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                storageCertifications.push();
                structs.AwsCertificationData storage storageCertification = storageCertifications[storageCertifications.length - 1];
                storageCertification.certificationNumber = certificationNumberFromCall;
            }
        }
    }

    function updateInspectorIdForSite(
        address sender,
        string memory id,
        structs.SiteData storage site
    ) public
    returns (bool isNew) {
        if (sender == site.inspectorAddresses[id] && keccak256(bytes(site.inspectorIds[sender])) != keccak256(bytes(id))) {
            return false;
        }
        
        require(site.inspectorAddresses[id] == address(0), "Inspector id already assigned");
        
        if (bytes(site.inspectorIds[sender]).length == 0) {
            site.inspectorIds[sender] = id;
            site.inspectorAddresses[id] = sender;
            return true;
        } else {
            delete site.inspectorAddresses[site.inspectorIds[sender]];
            site.inspectorIds[sender] = id;
            site.inspectorAddresses[id] = sender;
            return false;
        }
    }

    function updateEngineerIdForSite(
        address sender,
        string memory id,
        structs.SiteData storage site
    ) public
    returns (bool isNew) {
        if (sender == site.engineerAddresses[id] && keccak256(bytes(site.engineerIds[sender])) != keccak256(bytes(id))) {
            return false;
        }
        
        require(site.engineerAddresses[id] == address(0), "Engineer id already assigned");
        
        if (bytes(site.engineerIds[sender]).length == 0) {
            site.engineerIds[sender] = id;
            site.engineerAddresses[id] = sender;
            return true;
        } else {
            delete site.engineerAddresses[site.engineerIds[sender]];
            site.engineerIds[sender] = id;
            site.engineerAddresses[id] = sender;
            return false;
        }
    }

    function inspectWeldForSite(
         address sender,
         structs.InspectWeldInput memory inspectWeldInput,
         structs.WeldLogRecordDataPrivate[] storage weldLogRecords
    ) public {
        structs.WeldLogRecordDataPrivate storage weldLogRecord = weldLogRecords[weldLogRecords.length - 1];

        require(weldLogRecord.inspector == address(0), "Already inspected");

        weldLogRecord.inspector = sender;
        weldLogRecord.inspectWeldMethod = inspectWeldInput.method;
        weldLogRecord.inspectWeldTimestamp = block.timestamp;
        weldLogRecord.inspectWeldUserProvidedDate = inspectWeldInput.inspectWeldUserProvidedDate;
        weldLogRecord.inspectWeldFail = inspectWeldInput.fail;
        weldLogRecord.inspectWeldReason = inspectWeldInput.reason;
        weldLogRecord.inspectWeldComment = inspectWeldInput.comment;
        weldLogRecord.inspectWeldRepair = inspectWeldInput.repair;
        for (uint i = 0; i < inspectWeldInput.files.length; i++) {
            weldLogRecord.inspectWeldFiles.push();
            weldLogRecord.inspectWeldFiles[weldLogRecord.inspectWeldFiles.length - 1].description = inspectWeldInput.files[i].description;
            weldLogRecord.inspectWeldFiles[weldLogRecord.inspectWeldFiles.length - 1].ipfsCid = inspectWeldInput.files[i].ipfsCid;
        }
    }

    function recordWeldForSite(
         address sender,
         structs.RecordWeldInput memory recordWeldInput,
         structs.WeldLogRecordDataPrivate[] storage weldLogRecords
    ) public {
        if (weldLogRecords.length > 0) {
            require(weldLogRecords[weldLogRecords.length - 1].inspector != address(0), "Previous weld has not been inspected");
        }

        if (recordWeldInput.reWeld) {
            require(weldLogRecords.length > 0, "Re-weld cannot be true on first weld");
            require(weldLogRecords[weldLogRecords.length - 1].inspectWeldFail, "Cannot re-weld if previous weld succeeded");
            require(weldLogRecords[weldLogRecords.length - 1].inspectWeldRepair, "Cannot re-weld if inspector did NOT recommend repair of previous weld");
        } else {
            require(weldLogRecords.length == 0, "Re-weld cannot be false on subsequent weld");
        }

        weldLogRecords.push();

        structs.WeldLogRecordDataPrivate storage weldLogRecord = weldLogRecords[weldLogRecords.length - 1];

        weldLogRecord.welder = sender;
        weldLogRecord.recordWeldTimestamp = block.timestamp;
        weldLogRecord.recordWeldUserProvidedDate = recordWeldInput.recordWeldUserProvidedDate;
        weldLogRecord.coupon = recordWeldInput.coupon;
        weldLogRecord.reWeld = recordWeldInput.reWeld;
        for (uint i = 0; i < recordWeldInput.numbers.length; i++) {
            weldLogRecord.numbers.push();
            weldLogRecord.numbers[weldLogRecord.numbers.length - 1].name = recordWeldInput.numbers[i].name;
            weldLogRecord.numbers[weldLogRecord.numbers.length - 1].value = recordWeldInput.numbers[i].value;
        }
        for (uint i = 0; i < recordWeldInput.strings.length; i++) {
            weldLogRecord.strings.push();
            weldLogRecord.strings[weldLogRecord.strings.length - 1].name = recordWeldInput.strings[i].name;
            weldLogRecord.strings[weldLogRecord.strings.length - 1].value = recordWeldInput.strings[i].value;
        }

        for (uint i = 0; i < recordWeldInput.files.length; i++) {
            weldLogRecord.recordWeldFiles.push();
            weldLogRecord.recordWeldFiles[weldLogRecord.recordWeldFiles.length - 1].description = recordWeldInput.files[i].description;
            weldLogRecord.recordWeldFiles[weldLogRecord.recordWeldFiles.length - 1].ipfsCid = recordWeldInput.files[i].ipfsCid;
        }
    }

    function registerWeldForSite(
         address sender,
         structs.RegisterWeldInput memory registerWeldInput,
         structs.SiteWeldData storage siteWeldData
    ) public
    returns (bool isNew) {
        structs.WeldLogDataPrivate storage weldLogData = siteWeldData.weldLog[registerWeldInput.weldId];

        isNew = weldLogData.engineer == address(0);

        if (isNew) {
            siteWeldData.weldIds.push(registerWeldInput.weldId);
            weldLogData.registerWeldTimestamp = block.timestamp;
        }

        weldLogData.engineer = sender;
        weldLogData.code = registerWeldInput.code;
        weldLogData.wpsId = registerWeldInput.wpsId;
        weldLogData.notifyEngineer = registerWeldInput.notifyMe;
        weldLogData.registerWeldUserProvidedDate = registerWeldInput.registerWeldUserProvidedDate;

        for (uint i = 0; i < registerWeldInput.files.length; i++) {
            weldLogData.registerWeldFiles.push();
            weldLogData.registerWeldFiles[weldLogData.registerWeldFiles.length - 1].description = registerWeldInput.files[i].description;
            weldLogData.registerWeldFiles[weldLogData.registerWeldFiles.length - 1].ipfsCid = registerWeldInput.files[i].ipfsCid;
        }
    }

    function updateWeldProcedureSpecificationIdForSite(
        address sender,
        string memory wpsId,
        structs.SiteData storage site,
        structs.FileData[] memory files
    ) public {
        for (uint i = 0; i < files.length; i++) {
            structs.FileData storage wpsSetUpFile = site.wpsSetUpFiles[wpsId].push();
            wpsSetUpFile.description = files[i].description;
            wpsSetUpFile.ipfsCid = files[i].ipfsCid;
        }

        if (bytes(site.wpsIdToEngineerId[wpsId]).length != 0) {
            return;
        }

        site.wpsIdList.push(wpsId);
        site.wpsIdToEngineerId[wpsId] = site.engineerIds[sender];
    }

    function updateWelderIdForSite(
        address sender,
        string memory id,
        structs.SiteData storage site,
        structs.FileData[] memory files
    ) public {
        for (uint i = 0; i < files.length; i++) {
            structs.FileData storage welderSetUpFile = site.welderSetUpFiles[sender].push();
            welderSetUpFile.description = files[i].description;
            welderSetUpFile.ipfsCid = files[i].ipfsCid;
        }

        if (sender == site.welderAddresses[id] && keccak256(bytes(site.welderIds[sender])) != keccak256(bytes(id))) {
            return;
        }
        
        require(site.welderAddresses[id] == address(0), "Welder id already assigned");
        
        if (bytes(site.welderIds[sender]).length == 0) {
            site.welderIdList.push(id);
        } else {
            delete site.welderAddresses[site.welderIds[sender]];
            for (uint i = 0; i < site.welderIdList.length; i++) {
                if (keccak256(bytes(site.welderIdList[i])) == keccak256(bytes(site.welderIds[sender]))) {
                    site.welderIdList[i] = id;
                    break;
                }
            }
        }

        site.welderIds[sender] = id;
        site.welderAddresses[id] = sender;
    }

    /**
     * Checks if inspector is valid and engineer or welder are registered
     * @dev The idea is that a person registering as an engineer or welder implies giving permission to show their personal information to a valid inspector
     */
    function hasPermissionToRead(
        structs.InspectorDataPrivate storage inspector,
        structs.EngineerDataPrivate storage engineer,
        structs.WelderDataPrivate storage welder
    ) public view returns (bool hasPermission) {
        bool isInspector = hasValidInspectorCertifications(inspector);
        if (!isInspector) {
            return false;
        }

        bool registeredAsEngineer = engineer.certifications.length > 0;
        bool registeredAsWelder = welder.files.length > 0;

        bool registeredAsEngineerOrWelder = registeredAsEngineer || registeredAsWelder;

        if (registeredAsEngineerOrWelder) {
            return true;
        } else {
            return false;
        }
    }
}