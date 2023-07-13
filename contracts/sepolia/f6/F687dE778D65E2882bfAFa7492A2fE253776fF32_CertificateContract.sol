// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CertificateContract {
    struct Certificate {
        address owner;
        string name;
        string issuingInstitution;
        uint256 date;
        string course;
        bool isValid;
        uint256 expirationDate;
    }

    mapping(bytes32 => Certificate) public certificates;
    mapping(address => mapping(bytes32 => bool)) public ownership;
    mapping(address => uint256) public stakedAmount;

    event CertificateIssued(
        bytes32 indexed certificateId,
        address owner,
        string name,
        string issuingInstitution,
        uint256 date,
        string course,
        uint256 expirationDate
    );

    event CertificateExpired(bytes32 indexed certificateId);

    function issueCertificate(
        string memory name,
        string memory issuingInstitution,
        uint256 date,
        string memory course,
        uint256 expirationPeriod
    ) public payable {
        bytes32 certificateId = keccak256(abi.encodePacked(msg.sender, name, issuingInstitution, date, course));
        require(certificates[certificateId].owner == address(0), "Certificate already issued");

        uint256 expirationDate = block.timestamp + expirationPeriod;

        Certificate memory certificate = Certificate(
            msg.sender,
            name,
            issuingInstitution,
            date,
            course,
            true,
            expirationDate
        );
        certificates[certificateId] = certificate;
        ownership[msg.sender][certificateId] = true;
        stakedAmount[msg.sender] += msg.value;

        emit CertificateIssued(certificateId, msg.sender, name, issuingInstitution, date, course, expirationDate);
    }

    function verifyCertificate(
        string memory name,
        string memory issuingInstitution,
        uint256 date,
        string memory course
    ) public view returns (bool isValid, address owner, string memory certificateName, string memory certificateInstitution, uint256 certificateDate, string memory certificateCourse, uint256 expirationDate) {
        bytes32 certificateId = keccak256(abi.encodePacked(msg.sender, name, issuingInstitution, date, course));
        Certificate memory certificate = certificates[certificateId];
        require(certificate.owner != address(0), "Certificate not found");

        return (
            certificate.isValid,
            certificate.owner,
            certificate.name,
            certificate.issuingInstitution,
            certificate.date,
            certificate.course,
            certificate.expirationDate
        );
    }

    function expireCertificate(bytes32 certificateId) public {
        Certificate storage certificate = certificates[certificateId];
        require(certificate.owner == msg.sender, "Unauthorized");
        require(certificate.isValid, "Certificate already expired");

        if (block.timestamp >= certificate.expirationDate) {
            certificate.isValid = false;

            emit CertificateExpired(certificateId);
        }
    }

    function withdrawStakedAmount() public {
        uint256 amount = stakedAmount[msg.sender];
        require(amount > 0, "No staked amount to withdraw");

        stakedAmount[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}