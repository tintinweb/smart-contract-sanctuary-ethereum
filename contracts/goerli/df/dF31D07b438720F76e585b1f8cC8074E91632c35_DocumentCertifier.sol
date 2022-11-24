/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract DocumentCertifier {

    struct Document {
        string id;
        string size;
        string owner;
        uint256 appraisedValue;
        string typeD;
        string hash; 
        uint256 blockNumber;
        string tsa;
    }

    mapping(string => Document) public certifiedDocumentsMap;

    Document[] public certifiedDocumentsArray;

    function certifyDocument(
        string memory _id,
        string memory _size,
        string memory _owner,
        uint256 _appraisedValue,
        string memory _typeD,
        string memory _hash,
        string memory _tsa
        
    ) 
        public
    {
        Document memory document = Document({
            id: _id, 
            size: _size,
            owner: _owner,
            appraisedValue: _appraisedValue,
            typeD: _typeD,
            hash: _hash,
            blockNumber: block.number,
            tsa: _tsa
        }); 

        certifiedDocumentsMap[_id] = document;
        certifiedDocumentsArray.push(document);
    }

    function allDocuments()
        public
        view
        returns (Document[] memory coll)
    {
        return certifiedDocumentsArray;
    }
}