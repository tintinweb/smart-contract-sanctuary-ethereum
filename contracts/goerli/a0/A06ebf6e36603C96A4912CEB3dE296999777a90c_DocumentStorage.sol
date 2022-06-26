/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

contract DocumentStorage {
    struct Document {
        string issuer;
        address issuerAddress;
        string issueDate;
        string documentType;
        string issuedTo;
        string link;
    }

    mapping(string => Document) public documentsById;

    function saveDocument(string memory id, string memory issuer, string memory issueDate, string memory documentType, 
    string memory issuedTo, string memory link) public {
        require(bytes(documentsById[id].issuer).length == 0, 'There is already a document with this id');

        documentsById[id] = Document({
            issuer: issuer,
            issuerAddress: msg.sender,
            issueDate: issueDate,
            documentType: documentType,
            issuedTo: issuedTo,
            link: link
        });
    }

    function getDocumentById(string memory id) public view returns (Document memory) {
        require(bytes(documentsById[id].issuer).length > 0, 'There is no document with this id');

        return documentsById[id];
    }
}