/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CWCert {
    address _owner = msg.sender;

    function owner() public view returns (address) {
        return _owner;
    }

    //Define contract deployer or owner

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    //Struct for each certificate

    struct Certificate {
        address owner_address;
        string owner_name;
        uint256 certificate_id;
        uint256 certificate_type_id;
        uint256 creation_date;
        address _institute_address;
        string _institute_name;
        string _certificate_type;
        string _additional_fields_key;
        string _additional_fields_value;
    }
    //Struct for each certificate type for organizations
    struct Certificate_type {
        address institute_address;
        string institute_name;
        uint256 type_id;
        string certificate_type;
        string additional_fields_key;
        string additional_fields_value;
    }
    //Organization issue certificate template

    struct IssueCertificateTemplate {
        address ownerAddress;
        string ownerName;
        uint256 certificatetypeid;
    }
    //Mapping each certificate id to recipent address

    mapping(uint256 => address) idCertificateAddress;

    //Registered institutes
    mapping(address => bool) registeredInstitutes;

    //Certificate templates of instute
    mapping(address => uint256[]) templatesOfInstute;

    mapping(uint256 => bool) isCertificateDeleted;

    mapping(uint256 => bool) isCertificateTypeDeleted;

    uint256 certificate_counter;
    uint256 certificate_type_counter;

    Certificate[] certificates;
    Certificate_type[] certificate_types;

    //Organization can create certificate template with that function
    function createCertificate(
        string memory institutename,
        string memory certificatetype,
        string memory additional_key,
        string memory additional_value
    ) external {
        require(
            registeredInstitutes[msg.sender] == true,
            "You don't have permission"
        );
        uint256 typeid = certificate_type_counter++;
        templatesOfInstute[msg.sender].push(typeid);
        if (
            bytes(additional_key).length < 0 ||
            bytes(additional_value).length < 0
        ) {
            additional_key = "";
            additional_value = "";
        }
        certificate_types.push(
            Certificate_type(
                msg.sender,
                institutename,
                typeid,
                certificatetype,
                additional_key,
                additional_value
            )
        );
    }

    function changeCertificateTypeStatus(uint256 id, bool state)
        external
        onlyOwner
    {
        isCertificateTypeDeleted[id] = state;
    }

    //Organization issuing certificate with IssueCertificateTemplate [["address","name",certificatetype id],["address","name",certificatetype id]]
    function issueCertificate(
        IssueCertificateTemplate[] calldata certificateTemplate
    ) external {
        for (uint256 i = 0; i < certificateTemplate.length; ++i) {
            issueCertificateInternal(
                certificateTemplate[i].ownerAddress,
                certificateTemplate[i].ownerName,
                certificateTemplate[i].certificatetypeid
            );
        }
    }

    //Organization can not use that function thats internal function using by issueCertificate function
    function issueCertificateInternal(
        address to,
        string memory ownername,
        uint256 certificatetypeid
    ) internal {
        require(
            msg.sender ==
                certificate_types[certificatetypeid].institute_address &&
                isCertificateTypeDeleted[certificatetypeid] == false &&
                registeredInstitutes[msg.sender] == true,
            "You don't have permission"
        );
        uint256 certificateid = certificate_counter++;
        idCertificateAddress[certificateid] = to;
        certificates.push(
            Certificate(
                to,
                ownername,
                certificateid,
                certificatetypeid,
                block.timestamp,
                certificate_types[certificatetypeid].institute_address,
                certificate_types[certificatetypeid].institute_name,
                certificate_types[certificatetypeid].certificate_type,
                certificate_types[certificatetypeid].additional_fields_key,
                certificate_types[certificatetypeid].additional_fields_value
            )
        );
    }

    function changeCertificateStatus(uint256 id, bool state)
        external
        onlyOwner
    {
        isCertificateDeleted[id] = state;
    }

    //Register or unregister of instutes wallet address
    function updateInstuteWallet(address organizationWallet, bool state)
        external
        onlyOwner
    {
        registeredInstitutes[organizationWallet] = state;
    }

    //Get msg.sender certificates with array
    function getMyCertificates() external view returns (Certificate[] memory) {
        Certificate[] memory temporary = new Certificate[](certificates.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < certificates.length; i++) {
            if (
                idCertificateAddress[i] == msg.sender &&
                isCertificateDeleted[i] == false
            ) {
                temporary[counter] = certificates[i];
                counter++;
            }
        }

        Certificate[] memory result = new Certificate[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    //Get owner address certificates with array
    function getAddressCertificates(address ownerAddres)
        external
        view
        returns (Certificate[] memory)
    {
        Certificate[] memory temporary = new Certificate[](certificates.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < certificates.length; i++) {
            if (
                idCertificateAddress[i] == ownerAddres &&
                isCertificateDeleted[i] == false
            ) {
                temporary[counter] = certificates[i];
                counter++;
            }
        }

        Certificate[] memory result = new Certificate[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temporary[i];
        }
        return result;
    }

    function checkRegistrationStatusWallet(address organizationWallet)
        external
        view
        returns (bool)
    {
        return (registeredInstitutes[organizationWallet]);
    }

    function checkTemplatesOfInstute(address organizationAddress)
        external
        view
        returns (uint256[] memory)
    {
        return (templatesOfInstute[organizationAddress]);
    }

    //Get certificate info by certificate number
    function getCertificateInfo(uint256 certificateNumber)
        external
        view
        returns (Certificate memory)
    {
        Certificate memory certificate = certificates[certificateNumber];
        return (certificate);
    }
}