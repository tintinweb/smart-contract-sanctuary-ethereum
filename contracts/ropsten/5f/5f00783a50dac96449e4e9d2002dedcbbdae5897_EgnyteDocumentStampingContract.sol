// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "Ownable.sol";

contract EgnyteDocumentStampingContract is Ownable{



    /**
     * @dev Store checksum according to the document id
     * @param documentId documentId to store
     * @param checksum checksum of the given document Id
     */
    function setChecksum(string memory documentId , string memory checksum) public onlyOwner {
        //documentToChecksumMapping[documentId] = checksum;
    }

    /**
     * @dev Store checksum according to the document id
     * @param documentToChecksumMappings documentId to store
     */
    function setChecksums(string[] memory documentToChecksumMappings) public onlyOwner {

    }



}