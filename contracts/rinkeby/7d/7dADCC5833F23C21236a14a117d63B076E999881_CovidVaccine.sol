// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Verify signature
 * @author Kizito Lechornai
 */
library CryptoSuite {
    /// signature methods.
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }
}

contract CovidVaccine {
    // State variables
    uint256 constant MAX_CERTIFICATION = 2;
    uint256[] public certificateIds;
    uint256[] public vaccineBatchIds;
    // Events
    event EntityAdded(address account, string role);
    event VaccineBatchAdded(uint batchId, address indexed manufacturer);
    event CertificateIssued(
        address indexed issuer,
        address indexed prover,
        uint certificateId
    );

    // Function modifier

    // Struct => Entity, VaccineBatch, Certificate
    // 1. Entity
    struct Entity {
        address account;
        Role role;
        uint[] certificateIds;
    }

    // 2. VaccineBatch
    struct VaccineBatch {
        uint256 id;
        string brand;
        uint[] certificateIds;
        address manufacturer;
    }

    // 3. Certificate
    struct Certificate {
        uint256 id;
        Entity issuer;
        Entity prover;
        bytes signature;
        Status status;
    }

    // Arrays
    mapping(address => Entity) public entities;
    mapping(uint256 => VaccineBatch) public vaccineBatches;
    mapping(uint256 => Certificate) public certificates;

    // Enum => Status, Role

    // 1. Status
    enum Status {
        Manufactured,
        Delivering_International,
        Stored,
        Delivering_Local,
        Delivered
    }

    // 2. Role
    enum Role {
        Issuer,
        Prover,
        Verifier
    }

    // Functions
    // 1. addEntity

    function addEntity(address _account, string memory _role) public {
        // add entity
        Role role = getRole(_role);
        uint[] memory certificatesIds = new uint[](MAX_CERTIFICATION);
        Entity memory entity = Entity(_account, role, certificatesIds);
        entities[_account] = entity;
        emit EntityAdded(entity.account, _role);
    }

    // 2. getRole
    function getRole(string memory _role) internal pure returns (Role) {
        bytes32 encodedRole0 = keccak256(abi.encode(_role));
        bytes32 encodedRole1 = keccak256(abi.encode("Issuer"));
        bytes32 encodedRole2 = keccak256(abi.encode("Prover"));
        bytes32 encodedRole3 = keccak256(abi.encode("Verifier"));
        if (encodedRole0 == encodedRole1) {
            return Role.Issuer;
        } else if (encodedRole0 == encodedRole2) {
            return Role.Prover;
        } else if (encodedRole0 == encodedRole3) {
            return Role.Verifier;
        }
        revert("Role doesn't exist");
    }

    // 3. addVaccineBatch
    function addVaccineBatch(string memory brand, address manufacturer)
        public
        returns (uint)
    {
        uint id = vaccineBatchIds.length;
        uint[] memory batchCertificatesIds = new uint[](MAX_CERTIFICATION);
        VaccineBatch memory batch = VaccineBatch(
            id,
            brand,
            batchCertificatesIds,
            manufacturer
        );
        vaccineBatches[id] = batch;
        vaccineBatchIds.push(id);
        emit VaccineBatchAdded(batch.id, batch.manufacturer);
        return id;
    }

    // 4. issueCertificate

    function issueCertificate(
        address _issuer,
        address _prover,
        bytes memory signature,
        string memory _status
    ) public returns (uint) {
        uint id = certificateIds.length;
        Entity memory issuer = entities[_issuer];
        require(issuer.role == Role.Issuer);

        Entity memory prover = entities[_prover];
        require(prover.role == Role.Prover);

        Status status = getStatus(_status);

        Certificate memory certificate = Certificate(
            id,
            issuer,
            prover,
            signature,
            status
        );

        certificates[id - 1] = certificate;
        certificateIds.push(id - 1);

        emit CertificateIssued(_issuer, _prover, id);

        return id - 1;
    }

    // 5. getStatus
    function getStatus(string memory status) internal pure returns (Status) {
        bytes32 encodedStatus = keccak256(abi.encode(status));
        bytes32 encodedStatus1 = keccak256(abi.encode("Manufactured"));
        bytes32 encodedStatus2 = keccak256(
            abi.encode("Delivering_International")
        );
        bytes32 encodedStatus3 = keccak256(abi.encode("Stored"));
        bytes32 encodedStatus4 = keccak256(abi.encode("Delivering_Local"));
        bytes32 encodedStatus5 = keccak256(abi.encode("Delivered"));

        if (encodedStatus == encodedStatus1) {
            return Status.Manufactured;
        } else if (encodedStatus == encodedStatus2) {
            return Status.Delivering_International;
        } else if (encodedStatus == encodedStatus3) {
            return Status.Stored;
        } else if (encodedStatus == encodedStatus4) {
            return Status.Delivering_Local;
        } else if (encodedStatus == encodedStatus5) {
            return Status.Delivered;
        }
        revert("Wrong status");
    }

    // 5. isMatchingSignature
    function isMatchingSignature(
        uint id,
        address issuer,
        bytes32 message
    ) public view returns (bool) {
        Certificate memory certificate = certificates[id];
        require(certificate.issuer.account == issuer);

        address recoveredSigner = CryptoSuite.recoverSigner(
            message,
            certificate.signature
        );

        return recoveredSigner == certificate.issuer.account;
    }
}