// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title CertificateVerification
 * @dev This contract allows the storage and retrieval of image hashes, and provides admin functionality
 */
contract CertificateVerification {
    string[] private hashList; // An array to store the image hashes
    address private deployer; // The address of the contract deployer
    mapping(address => bool) private admins; // Mapping of admin addresses

    /**
     * @dev Modifier to restrict access to admin only
     */
    modifier onlyAdmin() {
        require(
            (msg.sender == deployer || admins[msg.sender]),
            "Only admin can perform this action"
        );
        _;
    }

    /**
     * @dev Constructor function to set the contract deployer
     */
    constructor() {
        deployer = msg.sender;
    }

    /**
     * @dev Function to add a new admin
     * @param _admin The address of the new admin to add
     */
    function addAdmin(address _admin) public onlyAdmin {
        admins[_admin] = true;
    }

    /**
     * @dev Function to remove an admin
     * @param _admin The address of the admin to remove
     */
    function removeAdmin(address _admin) public onlyAdmin {
        admins[_admin] = false;
    }

    /**
     * @dev Function to add a new image hash
     * @param _imageHash The image hash to add
     */
    function addImageHash(string memory _imageHash) public onlyAdmin {
        bytes32 hashBytes = keccak256(bytes(_imageHash));
        for (uint i = 0; i < hashList.length; i++) {
            if (keccak256(bytes(hashList[i])) == hashBytes) {
                revert("Hash already exists");
            }
        }
        hashList.push(_imageHash);
    }

    /**
     * @dev Function to get an image hash by its value
     * @param _hashValue The value of the image hash to retrieve
     * @return The image hash that matches the given value
     */
    function getHashByValue(
        string memory _hashValue
    ) public view returns (string memory) {
        bytes32 hashBytes = keccak256(bytes(_hashValue));
        for (uint i = 0; i < hashList.length; i++) {
            if (keccak256(bytes(hashList[i])) == hashBytes) {
                return hashList[i];
            }
        }
        revert("Hash not found");
    }

    /**
     * @dev Function to get all image hashes stored in the contract
     * @return An array containing all image hashes stored in the contract
     */
    function getAllHashes() public view returns (string[] memory) {
        return hashList;
    }

    /**
     * @dev Function to check if an address is an admin
     * @param _address The address to check
     * @return A boolean indicating whether the address is an admin or not
     */
    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    /**
     * @dev Function to get the deployer address
     * @return The address of the deployer
     */
    function getDeployerAddress() public view returns (address) {
        return deployer;
    }
}