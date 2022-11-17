/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error InvalidOrganization(address organization);
error InvalidUniversity(address sender);
error InvalidCertifier(address sender);
error InvalidSuperior(address sender);
error InvalidRevoker(address sender);
error ExistentCertificate(bytes32 certificateId, uint256 issueDate);
error InexistentCertificate(bytes32 certificateId);
error ExistentCertifier(address certifier);
error InvalidDates(uint256 issueDate, uint256 expirationDate);

contract CertificateManagement {
    struct CertificateStatus {
        bool invalid;
        string description;
    }

    struct University {
        bool active;
        string URI;
    }

    struct Certificate {
        address certifier;
        address university;
        uint256 issueDate;
        uint256 expirationDate;
    }

    struct CompleteCertificate {
        Certificate data;
        CertificateStatus status;
    }

    mapping(bytes32 => Certificate) private s_certificates;
    mapping(bytes32 => CertificateStatus) private s_revokedCertificates;
    mapping(address => bool) private s_organizations;
    mapping(address => University) private s_universities;
    mapping(address => string) private s_universityDiscreditReason;
    mapping(address => address) private s_certifierToUniversity;

    event OrganizationMemberAdded(
        address indexed organization,
        address indexed newMember
    );

    event OrganizationMemberRemoved(
        address indexed organization,
        address indexed removedMember
    );

    event UniversityAdded(
        address indexed organization,
        address indexed university
    );

    event UniversityDiscredited(
        address indexed organization,
        address indexed university,
        string reason
    );

    event CertifierAdded(address indexed university, address indexed certifier);

    event CertifierRemoved(
        address indexed certifierSuperior,
        address indexed certifier
    );

    event CertificateRegistered(
        address indexed certifier,
        bytes32 indexed certificateId
    );

    event CertificateRevoked(
        address indexed revoker,
        bytes32 indexed certificateId,
        string reason
    );

    modifier onlyOrganization() {
        if (!s_organizations[msg.sender]) {
            revert InvalidOrganization(msg.sender);
        }

        _;
    }

    modifier validUniversity(address university) {
        if (!s_universities[university].active) {
            revert InvalidUniversity(university);
        }

        _;
    }

    modifier onlyCertifierOrSuperior(address certifier) {
        address adminUniversity = s_certifierToUniversity[certifier];

        if (adminUniversity == address(0x0)) {
            revert InvalidCertifier(certifier);
        }

        bool validOrganization = s_organizations[msg.sender];

        bool isSameAdmin = adminUniversity == msg.sender;

        bool validSuperior = validOrganization || isSameAdmin;

        bool isCertifierItself = msg.sender == certifier;

        if (!validSuperior && !isCertifierItself) {
            revert InvalidSuperior(msg.sender);
        }

        _;
    }

    modifier onlyCertifier() {
        if (s_certifierToUniversity[msg.sender] == address(0x0)) {
            revert InvalidCertifier(msg.sender);
        }

        _;
    }

    modifier onlyNewCertificate(bytes32 certificateId) {
        if (s_certificates[certificateId].issueDate != 0) {
            revert ExistentCertificate(
                certificateId,
                s_certificates[certificateId].issueDate
            );
        }

        _;
    }

    modifier onlyNewCertifiers(address certifierAddress) {
        if (s_certifierToUniversity[certifierAddress] != address(0x0)) {
            revert ExistentCertifier(certifierAddress);
        }

        _;
    }

    modifier validDates(uint256 issueDate, uint256 expirationDate) {
        bool hasInvalidDate = issueDate == 0 ||
            (expirationDate != 0 && expirationDate <= issueDate);

        if (hasInvalidDate) {
            revert InvalidDates(issueDate, expirationDate);
        }

        _;
    }

    modifier onlyValidRevoker(bytes32 certificateId) {
        address universityCertificate = s_certificates[certificateId]
            .university;

        bool validOrganizatizon = s_organizations[msg.sender];

        bool isSameAdmin = msg.sender == universityCertificate ||
            universityCertificate == s_certifierToUniversity[msg.sender];

        bool isValidUniversity = s_universities[universityCertificate].active;

        bool validRevoker = validOrganizatizon ||
            (isValidUniversity && isSameAdmin);

        if (!validRevoker) {
            revert InvalidRevoker(msg.sender);
        }

        _;
    }

    constructor() {
        s_organizations[msg.sender] = true;
    }

    function addOrganization(address account) external onlyOrganization {
        s_organizations[account] = true;

        emit OrganizationMemberAdded(msg.sender, account);
    }

    function removeOrganization(address account) external onlyOrganization {
        if (!s_organizations[account]) {
            revert InvalidOrganization(account);
        }

        delete s_organizations[account];

        emit OrganizationMemberRemoved(msg.sender, account);
    }

    function addUniversity(address account, string memory universityURI)
        external
        onlyOrganization
    {
        s_universities[account] = University(true, universityURI);

        emit UniversityAdded(msg.sender, account);
    }

    function discreditUniversity(address account, string memory reason)
        external
        onlyOrganization
    {
        s_universities[account].active = false;

        s_universityDiscreditReason[account] = reason;

        emit UniversityDiscredited(msg.sender, account, reason);
    }

    function addCertifier(address account)
        external
        validUniversity(msg.sender)
        onlyNewCertifiers(account)
    {
        s_certifierToUniversity[account] = msg.sender;

        emit CertifierAdded(msg.sender, account);
    }

    function removeCertifier(address account)
        external
        onlyCertifierOrSuperior(account)
    {
        delete s_certifierToUniversity[account];

        emit CertifierRemoved(msg.sender, account);
    }

    function registerCertificate(
        bytes32 certificateId,
        uint256 issueDate,
        uint256 expirationDate
    )
        external
        onlyCertifier
        onlyNewCertificate(certificateId)
        validDates(issueDate, expirationDate)
    {
        address universityAddress = s_certifierToUniversity[msg.sender];

        University memory certifierUniversity = s_universities[
            universityAddress
        ];

        if (!certifierUniversity.active) {
            revert InvalidUniversity(universityAddress);
        }

        s_certificates[certificateId] = Certificate(
            msg.sender,
            universityAddress,
            issueDate,
            expirationDate
        );

        emit CertificateRegistered(msg.sender, certificateId);
    }

    function revokeCertificate(bytes32 certificateId, string memory reason)
        external
        onlyValidRevoker(certificateId)
    {
        if (s_certificates[certificateId].issueDate == 0) {
            revert InexistentCertificate(certificateId);
        }

        s_revokedCertificates[certificateId] = CertificateStatus(true, reason);

        emit CertificateRevoked(msg.sender, certificateId, reason);
    }

    function verifyCertificate(
        bytes32 certificateId,
        Certificate memory certificate
    ) internal view returns (CertificateStatus memory) {
        CertificateStatus memory revokedCertificate = s_revokedCertificates[
            certificateId
        ];

        bool isExpired = certificate.expirationDate != 0 &&
            block.timestamp >= certificate.expirationDate;

        bool isInvalid = certificate.issueDate == 0 ||
            revokedCertificate.invalid ||
            isExpired;

        string memory description = isExpired
            ? 'Certificado expirado'
            : revokedCertificate.description;

        return CertificateStatus(isInvalid, description);
    }

    function getCertificate(bytes32 certificateId)
        external
        view
        returns (CompleteCertificate memory)
    {
        Certificate memory certificate = s_certificates[certificateId];
        CertificateStatus memory status = verifyCertificate(
            certificateId,
            certificate
        );

        return CompleteCertificate(certificate, status);
    }

    function isOrganization(address account) external view returns (bool) {
        return s_organizations[account];
    }

    function getUniversityOfCertifier(address certifier)
        external
        view
        returns (address)
    {
        return s_certifierToUniversity[certifier];
    }

    function getUniversity(address university)
        external
        view
        returns (University memory)
    {
        return s_universities[university];
    }

    function getUniversityDiscreditReason(address university)
        external
        view
        returns (string memory)
    {
        return s_universityDiscreditReason[university];
    }
}