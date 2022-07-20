/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// File: contracts/certificate.sol


pragma solidity ^0.8.4;

contract CWCert {
    address _owner = msg.sender;

    function owner() public view returns (address) {
        return _owner;
    }

    //Define contract deployer,owner

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    //Event emiting from Issue Certificate function

    event IssueCertificate(IssueCertificateTemplate[] indexed certificateTemplate);

    //When organization created certificate template emiting here



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

    mapping(address => uint256[]) addressCertificates;
    
    //Registered institutes 
    mapping(address => bool) registeredInstitutes;
    
    //Certificate templates of instute
    mapping(address => uint256[]) templatesOfInstute;

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
    ) public  {
        require(
                registeredInstitutes[msg.sender]==true,
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

    //Organization issuing certificate with IssueCertificateTemplate [["address","name",certificatetype id],["address","name",certificatetype id]]
    function issueCertificate(
        IssueCertificateTemplate[] calldata certificateTemplate
    ) public {
        for (uint256 i = 0; i < certificateTemplate.length; ++i) {
            issueCertificateInternal(
                certificateTemplate[i].ownerAddress,
                certificateTemplate[i].ownerName,
                certificateTemplate[i].certificatetypeid
            );
        }
        emit IssueCertificate(certificateTemplate);
    }

    //Organization can not use that function thats internal function using by issueCertificate function
    function issueCertificateInternal(
        address to,
        string memory ownername,
        uint256 certificatetypeid
    ) internal {
        require(
            msg.sender ==
                certificate_types[certificatetypeid].institute_address,
            "You don't have permission"
        );
        uint256 certificateid = certificate_counter++;
        addressCertificates[to].push(certificateid);
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

    //Register or unregister of instutes wallet address
    function updateInstuteWallet(address organizationWallet,bool state) public onlyOwner{
        registeredInstitutes[organizationWallet] = state;
    }

    function checkRegistrationStatusWallet(address organizationWallet)public view returns(bool){
        return(registeredInstitutes[organizationWallet]);
    }

    function checkTemplatesOfInstute(address organizationAddress)
        public
        view
        returns (uint256[] memory)
    {
        return (templatesOfInstute[organizationAddress]);
    }

    //Get certificate info by certificate number
    function getCertificateInfo(uint256 certificateNumber)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            string memory,
            string memory,
            string memory
        )
    {
        Certificate storage cert = certificates[certificateNumber];
        return (
            cert.owner_address,
            cert.owner_name,
            cert.certificate_id,
            cert.certificate_type_id,
            cert.creation_date,
            cert._institute_address,
            cert._institute_name,
            cert._certificate_type,
            string(
                abi.encodePacked(
                    cert._additional_fields_key,
                    ":",
                    cert._additional_fields_value
                )
            )
        );
    }

    //Returns certificates ids of address
    function getCertificateInfoByAddress(address owneraddress)
        public
        view
        returns (uint256[] memory)
    {
        return (addressCertificates[owneraddress]);
    }
}