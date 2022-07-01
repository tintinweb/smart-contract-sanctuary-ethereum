/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// File: contracts/certificate.sol



pragma solidity ^0.8.4;



contract CWCert {

    

    address _owner = msg.sender;



    function owner() public view returns (address) {

        return _owner;

    }



    modifier onlyOwner() {

        require(msg.sender == _owner);

        _;

    }



    //Total certificate counter

    uint256 public certificate_counter;



    //Total certificate type counter

    uint256 public certificate_type_counter;



    //For each certificate

    mapping(uint256 => string) ipfsLink;

    mapping(uint256 => uint256) dateIssue;

    mapping(uint256 => address) issuer;

    mapping(uint256 => address) recipient;

    mapping(uint256 => uint256) certificateId;

    mapping(uint256 => string) certificateType;



    //For certificate type

    mapping(address => string) certificateTypeName;

    mapping(address => uint256) certificateTypeId;



    //Struct for mass certificate sending



    struct CertifacateProperties {

        string ipfsUrl;

        address certificateRecipient;

    }



    //Register certificate with name

    function createCertificate(

        string memory _certificateTypeName,

        address certificateOwner

    ) public onlyOwner {

        certificateTypeName[certificateOwner] = _certificateTypeName;

        uint256 certificateTypeNumber = certificate_type_counter++;

        certificateTypeId[certificateOwner] = certificateTypeNumber;

    }



    function issueCertificateBatch(CertifacateProperties[] memory dataList)

        public

    {

        for (uint256 i = 0; i < dataList.length; i++) {

            issueCertificate(

                dataList[i].ipfsUrl,

                dataList[i].certificateRecipient

            );

        }

    }



    function issueCertificate(string memory url, address to) public {

        require(

            certificateTypeId[msg.sender] > 0,

            "Issuer not registered to register a certificate"

        );

        uint256 id = certificate_counter++;

        certificateId[id] = id;

        ipfsLink[id] = url;

        dateIssue[id] = block.timestamp;

        issuer[id] = msg.sender;

        recipient[id] = to;

        certificateType[id] = certificateTypeName[msg.sender];

    }



    function getCertificateInfo(uint256 certificateNumber)

        public

        view

        returns (

            string memory,

            string memory,

            uint256,

            address,

            address

        )

    {

        return (

            certificateType[certificateNumber - 1],

            ipfsLink[certificateNumber - 1],

            dateIssue[certificateNumber - 1],

            issuer[certificateNumber - 1],

            recipient[certificateNumber - 1]

        );

    }

}