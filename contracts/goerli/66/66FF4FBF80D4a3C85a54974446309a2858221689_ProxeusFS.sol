// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Proxeus File Storage Contract
/// @notice ProxeusFS provides a store to register & sign hashes of documents
/// @dev ProxeusFS stores unique file hashes, lets users sign stored hashes and provides information about who stored & signed hashes
contract ProxeusFS {

    struct File {
        address issuer;
        bytes32 data;
        bool exists;
        mapping(address => bool) signers;
        mapping(uint256 => address) signerIndex;
        uint256 signersCount;
    }

    mapping(bytes32 => File) public files;

    event UpdatedEvent(bytes32 indexed hash);
    event FileSignedEvent(bytes32 indexed hash, address indexed signer);

    modifier fileMustExist(bytes32 _hash) {
        require(files[_hash].exists, "file does not exist");
        _;
    }

    /// @notice Function registerFile lets users store a new hash
    /// @dev Function registerFile lets users store a bytes32 keccak hash if not existing yet, together with a bytes32 extra data field and the address of the message sender
    /// @param _hash bytes32 - the keccak hash of a file
    /// @param _data bytes32 - additional data to be associated with the hash
    function registerFile(bytes32 _hash, bytes32 _data) external {
        require(!files[_hash].exists, "file already exists");

        files[_hash].issuer = msg.sender;
        files[_hash].data = _data;
        files[_hash].exists = true;
        files[_hash].signersCount = 0;

        emit UpdatedEvent(_hash);
    }

    /// @notice Function verifyFile lets users verify whether a file hash has been registered and by whom
    /// @dev Function verifyFile lets users verify whether the provided bytes32 keccak hash has been registered and returns the address of the message sender
    /// @param _hash bytes32 - the keccak hash of a file
    /// @return exists bool - boolean indicating whether the provided hash is registered or not
    /// @return issuer address - the address of the message sender of the registerFile operation in case the has is registered
    function verifyFile(bytes32 _hash) external view returns (bool exists, address issuer) {
        return (files[_hash].exists, files[_hash].issuer);
    }

    /// @notice Function signFile lets users sign a hash
    /// @dev Function signFile lets users sign the provided bytes32 keccak hash by storing the message sender address if the hash as been registered before
    /// @param _hash bytes32 - the keccak hash of a file
    function signFile(bytes32 _hash) external fileMustExist(_hash) {
        require(!files[_hash].signers[msg.sender], "file already signed by sender");

        files[_hash].signerIndex[files[_hash].signersCount] = msg.sender;
        files[_hash].signersCount++;
        files[_hash].signers[msg.sender] = true;

        emit FileSignedEvent(_hash, msg.sender);
    }

    /// @notice Function getFileSigners lets users retrieve the list of signers of a hash
    /// @dev Function getFileSigners returns the list of addresses that signed the provided keccak hash if the hash is registered
    /// @param _hash bytes32 - the keccak hash of a file
    /// @return address[] - list of signers of the hash, reverts if hash not registered
    function getFileSigners(bytes32 _hash) external view fileMustExist(_hash) returns (address[] memory) {
        //map to array
        address[] memory signerAddresses = new address[](files[_hash].signersCount);
        for (uint256 i = 0; i < files[_hash].signersCount; i++) {
            address signerAddress = files[_hash].signerIndex[i];
            signerAddresses[i] = signerAddress;
        }
        return signerAddresses;
    }
}