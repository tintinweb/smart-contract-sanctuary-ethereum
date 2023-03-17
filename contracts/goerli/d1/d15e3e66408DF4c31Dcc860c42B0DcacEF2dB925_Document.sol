// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Document {
    mapping(address => mapping(uint256 => string)) private userDocuments;
    mapping(uint256 => string) private documentLinks;

    // Add Document for a link
    function addDocumentLink(
        uint256 _documentId,
        string memory _documentLink
    ) public {
        userDocuments[msg.sender][_documentId] = _documentLink;
        documentLinks[_documentId] = _documentLink;
    }

    // Get Document Link
    function getDocumentLink(
        uint256 _documentId
    ) public view returns (string memory) {
        return documentLinks[_documentId];
    }

    // Get Single Document Link
    function getUserDocumentLink(
        address _user,
        uint256 _documentId
    ) public view returns (string memory) {
        return userDocuments[_user][_documentId];
    }
}