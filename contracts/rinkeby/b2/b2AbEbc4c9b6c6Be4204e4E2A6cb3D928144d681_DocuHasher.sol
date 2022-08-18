// SPDX-License-Identifier: Hedera Foundation

pragma solidity ^0.8.15;

contract DocuHasher {

    /**
     * @dev
     * events which are thrown when a new document has been sealed or revoked
     */
    event DocumentSealed(string documentHash, uint256 sealingBlock);
    event DocumentRevoced(string documentHash, uint256 revokeBlock);

    /**
     * @dev
     * access modifier for the owner of a seal
     * @param hash is the hash to check
     */
    modifier onlyOwner(string calldata hash) {
        require(msg.sender == sealToHash[hash].sealOwner, "Only the owner of the seal can call this function");
        _;
    }

    /**
     * @dev
     * modifier to check if a seal already exists
     * @param hash is the hash to check
     * @param exists is a flag to tell check wether to check for an existing hash or a non-existing hash
     */
    modifier sealExists(string calldata hash, bool exists) {
        if(exists) {
            require(hasBeenSealed[hash], "The document to this hash has not been sealed yet.");
        } else {
            require(!hasBeenSealed[hash], "This document has already been sealed before");
        }
        _;
    }

    /**
     * @dev
     * struct which stores a single seal
     */
    struct Seal {
        uint256 sealingBlock;
        uint256 revokingBlock;
        address sealOwner;
    }

    /**
     * @dev
     * empty constructor of the contract
     */
    constructor(){
    }

    /**
     * @dev
     * mapping which checks if a hash has already been sealed
     */
    mapping(string => bool) hasBeenSealed;

    /**
     * @dev
     * mapping which uses the hash as the key to a linked Seal object
     */
    mapping(string => Seal) sealToHash;

    /**
     * @dev
     * public function to create a seal if the hash has not been used before
     * @param hash is the hash to check
     */
    function seal(string calldata hash) public sealExists(hash, false) {
        hasBeenSealed[hash] = true;
        sealToHash[hash] = Seal(block.number, 0, msg.sender);
        emit DocumentSealed(hash, block.number);
    }

    /**
     * @dev
     * public getter which retrieves a seal object to a given hash (if existing)
     * @param hash is the hash to check
     */
    function getSeal(string calldata hash) public view sealExists(hash, true) returns (Seal memory _seal){
        return sealToHash[hash];
    }

    /**
     * @dev
     * public function which allows the user to check if a seal has been revoked
     * @param hash is the hash to check
     */
    function checkSealRevocationStatus(string calldata hash) public view sealExists(hash, true) returns (bool) {
        bool check;
        if (sealToHash[hash].revokingBlock == 0) {
            check = true;
        } else {
            check = false;
        }
        return check;
    }

    /**
     * @dev
     * public function which allows the owner of a seal to revoke it
     * @param hash is the hash to revoke
     */
    function revokeSeal(string calldata hash) public sealExists(hash, true) onlyOwner(hash) {
        require(sealToHash[hash].revokingBlock == 0, "This document has already been revoked");
        sealToHash[hash].revokingBlock = block.number;
        emit DocumentRevoced(hash, block.number);
    }

}