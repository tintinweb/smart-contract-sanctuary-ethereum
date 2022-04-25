// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "Ownable.sol";

contract EgnyteDocumentStampingContract is Ownable{

    mapping (string => string) documentToChecksumMapping;
    struct DocumentId {
          string documentId;
          string checksum;
       }

    /**
     * @dev Store checksum according to the document id
     * @param documentId documentId to store
     * @param checksum checksum of the given document Id
     */
    function setChecksum(string memory documentId , string memory checksum) public onlyOwner {
        documentToChecksumMapping[documentId] = checksum;
    }

    /**
     * @dev Store checksum according to the document id
     * @param documentToChecksumMappings documentId to store
     */
    function setChecksums(DocumentId[] memory documentToChecksumMappings) public onlyOwner {
        for(uint i=0; i<documentToChecksumMappings.length; i++){
            documentToChecksumMapping[documentToChecksumMappings[i].documentId]= documentToChecksumMappings[i].checksum;
        }
    }

    /**
     * @dev Return value
     * @param documentId documentId to store
     * @return value of 'checksum'
     */
    function getChecksum(string memory documentId) public view returns (string memory) {
        return documentToChecksumMapping[documentId];
    }

}